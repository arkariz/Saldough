import 'dart:convert';
import 'dart:typed_data';

import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_journal_record.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_finalizer.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_codec.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_resolver.dart';
import 'package:saldough/features/notification_capture/domain/services/transaction_from_draft.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Id transaksi dari id tangkapan (ADR-044 §3.5): menerapkan keputusan yang
/// sama dua kali (proses dimatikan di tengah jalan) tidak pernah menggandakan.
String captureTransactionId(String captureId) => 'cap_$captureId';

/// Hasil [ApplyCaptureJournal].
final class JournalApplyResult {
  /// Membuat [JournalApplyResult].
  const JournalApplyResult({this.recorded = 0, this.dismissed = 0, this.movedToInbox = 0, this.dropped = 0});

  /// Tanpa jurnal.
  static const none = JournalApplyResult();

  /// Transaksi yang dicatat (termasuk yang sudah ada dari percobaan sebelumnya).
  final int recorded;

  /// Tangkapan yang diabaikan.
  final int dismissed;

  /// Keputusan Catat yang gagal diterapkan: kembali jadi kartu di kotak masuk.
  final int movedToInbox;

  /// Entri tanpa keputusan: dibuang, tangkapannya diproses biasa dari antrean.
  final int dropped;

  /// Ada yang diterapkan.
  bool get isEmpty => recorded + dismissed + movedToInbox + dropped == 0;
}

/// Menerapkan jurnal notifikasi bertindak ke Hive saat aplikasi dibuka
/// (ADR-044 §3.5). Aplikasi tetap satu-satunya penulis ke Hive: mesin tanpa
/// layar hanya membaca dan native hanya mencatat keputusan.
///
/// Per entri, tiap langkah idempoten dan urutannya aman bila proses dimatikan
/// di antaranya: catat (id dari id tangkapan, dilewati bila sudah ada) → buang
/// dari kotak masuk → tandai terproses → ack antrean native → ack jurnal.
///
/// - `record`: transaksi dari draf yang diselesaikan, tertaut ke kemunculan
///   rutin dan pos periodenya (`CaptureFinalizer`). Bila dompetnya sudah tidak
///   ada atau penyimpanan gagal, tangkapannya menjadi kartu di kotak masuk
///   dengan alasan, bukan hilang.
/// - `dismiss`: tangkapan dibuang.
/// - tanpa keputusan: entri dibuang; tangkapannya masih di antrean native dan
///   diproses biasa jadi kartu.
final class ApplyCaptureJournal {
  /// Membuat [ApplyCaptureJournal].
  const ApplyCaptureJournal({
    required this.gateway,
    required this.store,
    required this.recordTransaction,
    required this.transactionRepository,
    required this.walletRepository,
    this.sourceIcons,
    this.recurringRules,
    this.finalizer = const CaptureFinalizer(),
    this.changes,
    this.recurringChanges,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Gerbang native (jurnal, antrean).
  final NotificationCaptureGateway gateway;

  /// Penyimpanan ikon aplikasi sumber; `null` = transaksi tanpa ikon.
  final SourceIconRepository? sourceIcons;

  /// Penyimpanan kotak masuk dan id terproses.
  final NotificationCaptureStore store;

  /// Use case pencatatan bersama.
  final RecordTransaction recordTransaction;

  /// Buku besar.
  final TransactionRepository transactionRepository;

  /// Dompet.
  final WalletRepository walletRepository;

  /// Rutin untuk tautan; `null` = tanpa.
  final RecurringRuleRepository? recurringRules;

  /// Penutup bersama (tautan rutin dan pos).
  final CaptureFinalizer finalizer;

  /// Sinyal kotak masuk berubah.
  final CaptureInboxChanges? changes;

  /// Sinyal rutin berubah (ada yang tertaut).
  final RecurringChanges? recurringChanges;

  final DateTime Function() _clock;

  /// Menerapkan seluruh jurnal. Tidak melempar: entri yang gagal dibaca atau
  /// diterapkan dibiarkan di jurnal (dicoba lagi pada pembukaan berikutnya;
  /// native membuang yang lebih dari 7 hari).
  Future<JournalApplyResult> call() async {
    if (!gateway.isSupported) return JournalApplyResult.none;
    final records = [...await gateway.journal()]..sort((a, b) => a.resolvedAt.compareTo(b.resolvedAt));
    if (records.isEmpty) return JournalApplyResult.none;

    final rules = (await recurringRules?.listRules())?.getOrElse((_) => const []) ?? const <RecurringRule>[];
    final activeWallets = {
      for (final w in (await walletRepository.listWallets()).getOrElse((_) => const []))
        if (w.isActive) w.id,
    };
    var recorded = 0;
    var dismissed = 0;
    var moved = 0;
    var dropped = 0;
    var linked = false;
    final done = <String>[];
    // Ikon aplikasi sumber ada di antrean native (mesin tanpa layar tidak menulis Hive).
    final icons = records.any((r) => r.decision == 'record') ? await _queuedIcons() : const <String, Uint8List>{};

    for (final record in records) {
      try {
        switch (record.decision) {
          case 'record':
            final outcome = await _applyRecord(record, rules, activeWallets, icons);
            if (outcome == null) continue;
            outcome.movedToInbox ? moved++ : recorded++;
            linked |= outcome.linked;
          case 'dismiss':
            await _finish(record.id);
            dismissed++;
          default:
            dropped++;
        }
        done.add(record.id);
      } on Object {
        // Dibiarkan di jurnal; dicoba lagi pada pembukaan berikutnya.
        continue;
      }
    }

    // Aplikasi terbuka: tangkapan kini kartu atau transaksi; notifikasi bertindak basi.
    await gateway.cancelActionable();
    if (done.isNotEmpty) await gateway.acknowledgeJournal(done);
    changes?.notify();
    if (linked) recurringChanges?.notifyChanged(source: this);
    return JournalApplyResult(recorded: recorded, dismissed: dismissed, movedToInbox: moved, dropped: dropped);
  }

  Future<Map<String, Uint8List>> _queuedIcons() async {
    final pending = (await gateway.pending()).getOrElse((_) => const []);
    return {
      for (final n in pending)
        if (n.icon != null) n.id: n.icon!,
    };
  }

  Future<({bool movedToInbox, bool linked})?> _applyRecord(
    CaptureJournalRecord record,
    List<RecurringRule> rules,
    Set<String> activeWallets,
    Map<String, Uint8List> icons,
  ) async {
    final payload = jsonDecode(record.payload) as Map<String, dynamic>;
    final entry = captureInboxEntryFromJson(payload['entry'] as Map<String, dynamic>);
    final match = _match(payload['match'], rules);
    var draft = enrichFromPlan(entry.draft, match);
    if (draft.sourceIconId == null && icons[entry.id] != null) {
      final iconId = (await sourceIcons?.save(icons[entry.id]!))?.fold((_) => null, (id) => id);
      if (iconId != null) draft = draft.copyWith(sourceIconId: () => iconId);
    }
    final date = draft.date ?? entry.capturedAt;
    final txId = captureTransactionId(entry.id);

    final ledger = (await transactionRepository.listTransactionsInMonth(date)).getOrElse((_) => const []);
    final exists = ledger.any((t) => t.id == txId);
    var linked = false;
    var tx = ledger.where((t) => t.id == txId).firstOrNull;
    if (!exists) {
      final walletsOk =
          draft.walletId != null &&
          activeWallets.contains(draft.walletId) &&
          (draft.toWalletId == null || activeWallets.contains(draft.toWalletId));
      final built = walletsOk ? transactionFromDraft(draft, id: txId, fallbackDate: entry.capturedAt) : null;
      if (built == null) {
        await _toInbox(entry, CaptureReviewReason.walletUnknown);
        return (movedToInbox: true, linked: false);
      }
      final transaction = await finalizer.finalize(built, match: match, linkedBy: RecurrenceLinkedBy.user);
      if ((await recordTransaction(transaction, source: this)).isLeft()) {
        await _toInbox(entry, CaptureReviewReason.walletUnknown);
        return (movedToInbox: true, linked: false);
      }
      linked = match != null;
      tx = transaction;
    }
    if (tx != null) await _logAuto(entry, draft, tx);
    await _finish(entry.id);
    return (movedToInbox: false, linked: linked);
  }

  /// Catat satu ketuk dari notifikasi dan mode otomatis masuk log "Tercatat
  /// otomatis" di kotak masuk (ADR-032 §3.6), seperti jalur proses biasa --
  /// tanpa ini transaksinya ada tetapi tab Otomatis kosong dan tidak bisa
  /// dibatalkan dari sana. Idempoten per id tangkapan; gagal menulis log tidak
  /// membatalkan transaksi.
  Future<void> _logAuto(CaptureInboxEntry entry, RecordDraft draft, Transaction tx) async {
    final auto = (await store.loadAutoRecorded()).getOrElse((_) => const []);
    if (auto.any((e) => e.captureId == entry.id)) return;
    await store.saveAutoRecorded([
      AutoRecordedEntry(
        captureId: entry.id,
        transactionId: tx.id,
        transactionDate: tx.date,
        kind: draft.kind,
        amountSen: tx.amount,
        appLabel: entry.appLabel,
        recordedAt: _clock(),
        note: tx.note,
        categoryId: tx.categoryId,
        iconId: draft.sourceIconId ?? entry.iconId,
        capturedAt: entry.capturedAt,
      ),
      ...auto,
    ]);
  }

  OccurrenceMatch? _match(Object? raw, List<RecurringRule> rules) {
    if (raw is! Map) return null;
    final rule = rules.where((r) => r.id == raw['ruleId']).firstOrNull;
    final date = DateTime.tryParse('${raw['date']}');
    if (rule == null || date == null) return null;
    return OccurrenceMatch(rule: rule, date: date, exact: raw['exact'] as bool? ?? false);
  }

  /// Tangkapan selesai ditangani: buang dari kotak masuk, tandai terproses,
  /// dan ack antrean native supaya tidak diproses lagi jadi kartu.
  Future<void> _finish(String captureId) async {
    final inbox = (await store.loadInbox()).getOrElse((_) => const []);
    if (inbox.any((e) => e.id == captureId)) {
      await store.saveInbox([
        for (final e in inbox)
          if (e.id != captureId) e,
      ]);
    }
    await _markProcessed(captureId);
    await gateway.acknowledge([captureId]);
  }

  /// Keputusan Catat tidak bisa diterapkan: tangkapan menjadi kartu dengan alasan.
  Future<void> _toInbox(CaptureInboxEntry entry, CaptureReviewReason reason) async {
    final inbox = (await store.loadInbox()).getOrElse((_) => const []);
    if (!inbox.any((e) => e.id == entry.id)) {
      await store.saveInbox([
        CaptureInboxEntry(
          id: entry.id,
          packageName: entry.packageName,
          appLabel: entry.appLabel,
          text: entry.text,
          capturedAt: entry.capturedAt,
          draft: entry.draft,
          possibleDuplicate: entry.possibleDuplicate,
          iconId: entry.iconId,
          patternId: entry.patternId,
          reviewReason: reason,
        ),
        ...inbox,
      ]);
    }
    await _markProcessed(entry.id);
    await gateway.acknowledge([entry.id]);
  }

  Future<void> _markProcessed(String captureId) async {
    final processed = (await store.loadProcessedIds()).getOrElse((_) => {});
    processed[captureId] = _clock();
    await store.saveProcessedIds(processed);
  }
}
