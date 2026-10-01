import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/record/domain/capture/notification/auto_record_policy.dart';
import 'package:saldough/features/record/domain/capture/notification/built_in_notification_patterns.dart';
import 'package:saldough/features/record/domain/capture/notification/capture_inbox_changes.dart';
import 'package:saldough/features/record/domain/capture/notification/capture_inbox_entry.dart';
import 'package:saldough/features/record/domain/capture/notification/captured_notification.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_capture_gateway.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_capture_settings.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_capture_store.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_draft_composer.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_pattern.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_text.dart';
import 'package:saldough/features/record/domain/capture/notification/transaction_from_draft.dart';
import 'package:saldough/features/record/domain/capture/record_draft.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Hasil satu putaran pemrosesan, untuk snackbar dan pengingat.
final class CaptureProcessResult {
  /// Membuat [CaptureProcessResult].
  const CaptureProcessResult({this.recorded = const [], this.queued = const []});

  /// Transaksi yang tercatat otomatis.
  final List<AutoRecordedEntry> recorded;

  /// Tangkapan yang masuk kotak masuk.
  final List<CaptureInboxEntry> queued;

  /// Tidak ada yang baru.
  bool get isEmpty => recorded.isEmpty && queued.isEmpty;
}

/// Memproses antrean tangkapan native (ADR-032 §3.1, §3.4, §3.5).
///
/// - *Single-flight*: pemicu yang datang selagi berjalan menjadwalkan satu
///   putaran lagi, bukan putaran paralel.
/// - Idempoten: id yang sudah diproses dicatat (7 hari) dan disimpan sesudah
///   setiap tangkapan, jadi crash sebelum *ack* tidak mencatat dua kali.
/// - Satu jalur tulis: [RecordTransaction], sama dengan CATAT.
final class ProcessCapturedNotifications {
  /// Membuat [ProcessCapturedNotifications].
  ProcessCapturedNotifications({
    required this.gateway,
    required this.store,
    required this.composer,
    required this.recordTransaction,
    required this.walletRepository,
    required this.transactionRepository,
    required this.categories,
    required this.currencyCode,
    required this.languageCode,
    this.changes,
    DateTime Function()? clock,
    String Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? (() => DateTime.now().microsecondsSinceEpoch.toString());

  /// Pintu layanan native.
  final NotificationCaptureGateway gateway;

  /// Penyimpanan setelan, kotak masuk, dan log.
  final NotificationCaptureStore store;

  /// Penyusun draf notifikasi.
  final NotificationDraftComposer composer;

  /// Use case tulis buku besar.
  final RecordTransaction recordTransaction;

  /// Dompet aktif.
  final WalletRepository walletRepository;

  /// Buku besar, untuk dugaan ganda.
  final TransactionRepository transactionRepository;

  /// Kategori terkini.
  final List<Category> Function() categories;

  /// Mata uang aplikasi.
  final String Function() currencyCode;

  /// Bahasa aplikasi.
  final String Function() languageCode;

  /// Sinyal perubahan kotak masuk, atau `null`.
  final CaptureInboxChanges? changes;

  final DateTime Function() _clock;
  final String Function() _newId;

  Future<CaptureProcessResult>? _running;
  bool _again = false;

  /// Memproses antrean. Pemicu ganda digabung.
  Future<CaptureProcessResult> call() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    return _running = _loop().whenComplete(() => _running = null);
  }

  Future<CaptureProcessResult> _loop() async {
    final recorded = <AutoRecordedEntry>[];
    final queued = <CaptureInboxEntry>[];
    do {
      _again = false;
      final result = await _run();
      recorded.addAll(result.recorded);
      queued.addAll(result.queued);
    } while (_again);
    if (recorded.isNotEmpty || queued.isNotEmpty) changes?.notify();
    return CaptureProcessResult(recorded: recorded, queued: queued);
  }

  Future<CaptureProcessResult> _run() async {
    if (!gateway.isSupported) return const CaptureProcessResult();
    final settings = (await store.loadSettings()).getOrElse((_) => const NotificationCaptureSettings());
    if (!settings.enabled) return const CaptureProcessResult();
    final pending = (await gateway.pending()).getOrElse((_) => const []);
    final now = _clock();

    final processed = (await store.loadProcessedIds()).getOrElse((_) => {})
      ..removeWhere((_, at) => CaptureRetention.expired(at, now));
    final inbox = [
      ...(await store.loadInbox())
          .getOrElse((_) => const [])
          .where((e) => !CaptureRetention.expired(e.capturedAt, now)),
    ];
    final auto = [
      ...(await store.loadAutoRecorded())
          .getOrElse((_) => const [])
          .where((e) => !CaptureRetention.expired(e.recordedAt, now)),
    ];
    if (pending.isEmpty) {
      await _save(processed, inbox, auto);
      return const CaptureProcessResult();
    }

    final wallets = (await walletRepository.listWallets()).getOrElse((_) => const []).where((w) => w.isActive).toList();
    final patterns = [
      ...(await store.loadPatterns()).getOrElse((_) => const []),
      for (final p in builtInNotificationPatterns)
        if (!settings.disabledBuiltInPatternIds.contains(p.id)) p,
    ];
    final policy = AutoRecordPolicy(settings.autoRecordLevel);
    final ledgers = <String, List<Transaction>>{};
    final recorded = <AutoRecordedEntry>[];
    final queued = <CaptureInboxEntry>[];
    final handled = <String>[];

    for (final notification in [...pending]..sort((a, b) => a.postedAt.compareTo(b.postedAt))) {
      handled.add(notification.id);
      if (processed.containsKey(notification.id)) continue;
      processed[notification.id] = now;
      final source = settings.activeSource(notification.packageName);
      final text = notification.text;
      if (source == null || NotificationText.looksLikeOtp(text) || !source.matchesKeywords(text)) {
        await _save(processed, inbox, auto);
        continue;
      }

      final composed = await composer.compose(
        notification,
        source: source,
        patterns: patterns,
        wallets: wallets,
        categories: categories(),
        currencyCode: currencyCode(),
        languageCode: languageCode(),
      );
      final draft = composed.draft;
      final date = draft.date ?? notification.postedAt;
      final ledger = ledgers[_monthKey(date)] ??= (await transactionRepository.listTransactionsInMonth(
        date,
      )).getOrElse((_) => const []);
      final duplicate =
          AutoRecordPolicy.matchesLedger(draft, date, ledger) ||
          _nearbyCapture(draft, notification, inbox: inbox, auto: auto);

      if (composed.autoEligible && !duplicate && policy.allows(draft)) {
        final entry = await _record(draft, notification, source.appLabel, now);
        if (entry != null) {
          auto.insert(0, entry);
          recorded.add(entry);
          ledgers.remove(_monthKey(date));
          await _save(processed, inbox, auto);
          continue;
        }
      }
      final entry = CaptureInboxEntry(
        id: notification.id,
        packageName: notification.packageName,
        appLabel: source.appLabel,
        text: text,
        capturedAt: notification.postedAt,
        draft: draft,
        possibleDuplicate: duplicate,
        icon: notification.icon,
      );
      inbox.insert(0, entry);
      queued.add(entry);
      await _save(processed, inbox, auto);
    }

    await gateway.acknowledge(handled);
    return CaptureProcessResult(recorded: recorded, queued: queued);
  }

  Future<AutoRecordedEntry?> _record(
    RecordDraft draft,
    CapturedNotification notification,
    String appLabel,
    DateTime now,
  ) async {
    final transaction = transactionFromDraft(draft, id: _newId(), fallbackDate: notification.postedAt);
    if (transaction == null) return null;
    final result = await recordTransaction(transaction, source: this);
    if (result.isLeft()) return null;
    return AutoRecordedEntry(
      captureId: notification.id,
      transactionId: transaction.id,
      transactionDate: transaction.date,
      kind: draft.kind,
      amountSen: transaction.amount,
      appLabel: appLabel,
      recordedAt: now,
      note: transaction.note,
      icon: notification.icon,
    );
  }

  /// Tangkapan lain bernominal sama dalam 10 menit (mis. notifikasi bank dan
  /// e-wallet untuk satu top up).
  bool _nearbyCapture(
    RecordDraft draft,
    CapturedNotification notification, {
    required List<CaptureInboxEntry> inbox,
    required List<AutoRecordedEntry> auto,
  }) {
    final amount = draft.amountSen;
    if (amount == null) return false;
    bool near(DateTime at) => at.difference(notification.postedAt).abs() <= const Duration(minutes: 10);
    return inbox.any((e) => e.id != notification.id && e.draft.amountSen == amount && near(e.capturedAt)) ||
        auto.any((e) => e.captureId != notification.id && e.amountSen == amount && near(e.transactionDate));
  }

  Future<void> _save(
    Map<String, DateTime> processed,
    List<CaptureInboxEntry> inbox,
    List<AutoRecordedEntry> auto,
  ) async {
    await store.saveProcessedIds(processed);
    await store.saveInbox(inbox);
    await store.saveAutoRecorded(auto);
  }

  static String _monthKey(DateTime d) => '${d.year}-${d.month}';
}

/// Aksi pengguna di kotak masuk (ADR-032 §3.6).
final class CaptureInboxActions {
  /// Membuat [CaptureInboxActions].
  const CaptureInboxActions({
    required this.store,
    required this.recordTransaction,
    required this.transactionRepository,
    required this.composer,
    required this.walletRepository,
    required this.categories,
    required this.currencyCode,
    required this.languageCode,
    this.changes,
  });

  /// Sinyal perubahan kotak masuk, atau `null`.
  final CaptureInboxChanges? changes;

  /// Penyimpanan.
  final NotificationCaptureStore store;

  /// Use case tulis buku besar (untuk Batalkan).
  final RecordTransaction recordTransaction;

  /// Buku besar.
  final TransactionRepository transactionRepository;

  /// Penyusun draf (untuk menafsirkan ulang dengan pola baru).
  final NotificationDraftComposer composer;

  /// Dompet aktif.
  final WalletRepository walletRepository;

  /// Kategori terkini.
  final List<Category> Function() categories;

  /// Mata uang aplikasi.
  final String Function() currencyCode;

  /// Bahasa aplikasi.
  final String Function() languageCode;

  /// Menghapus item kotak masuk [id] (Abaikan, atau sesudah dicatat lewat
  /// CATAT). Teksnya ikut terhapus.
  Future<Either<Failure, Unit>> remove(String id) async {
    final inbox = (await store.loadInbox()).getOrElse((_) => const []);
    final saved = await store.saveInbox([
      for (final e in inbox)
        if (e.id != id) e,
    ]);
    changes?.notify();
    return saved;
  }

  /// Membatalkan transaksi otomatis [entry]: menghapusnya dari buku besar
  /// lewat [RecordTransaction.delete], lalu dari log. Transaksi yang sudah
  /// dihapus pengguna cukup dihapus dari log.
  Future<Either<Failure, Unit>> undo(AutoRecordedEntry entry) async {
    final ledger = await transactionRepository.listTransactionsInMonth(entry.transactionDate);
    switch (ledger) {
      case Left(:final value):
        return left(value);
      case Right(:final value):
        final transaction = value.where((t) => t.id == entry.transactionId).firstOrNull;
        if (transaction != null) {
          final deleted = await recordTransaction.delete(transaction);
          if (deleted.isLeft()) return deleted;
        }
    }
    final auto = (await store.loadAutoRecorded()).getOrElse((_) => const []);
    final saved = await store.saveAutoRecorded([
      for (final e in auto)
        if (e.transactionId != entry.transactionId) e,
    ]);
    changes?.notify();
    return saved;
  }

  /// Menafsirkan ulang item [id] sesudah pola baru disimpan; drafnya
  /// diganti, tidak dicatat otomatis (pengguna sedang meninjaunya).
  Future<CaptureInboxEntry?> reinterpret(String id) async {
    final settings = (await store.loadSettings()).getOrElse((_) => const NotificationCaptureSettings());
    final inbox = [...(await store.loadInbox()).getOrElse((_) => const [])];
    final index = inbox.indexWhere((e) => e.id == id);
    if (index < 0) return null;
    final entry = inbox[index];
    final source = settings.activeSource(entry.packageName);
    if (source == null) return entry;
    final wallets = (await walletRepository.listWallets()).getOrElse((_) => const []).where((w) => w.isActive).toList();
    final patterns = <NotificationPattern>[
      ...(await store.loadPatterns()).getOrElse((_) => const []),
      for (final p in builtInNotificationPatterns)
        if (!settings.disabledBuiltInPatternIds.contains(p.id)) p,
    ];
    final composed = await composer.compose(
      CapturedNotification(
        id: entry.id,
        packageName: entry.packageName,
        title: '',
        body: entry.text,
        postedAt: entry.capturedAt,
      ),
      source: source,
      patterns: patterns,
      wallets: wallets,
      categories: categories(),
      currencyCode: currencyCode(),
      languageCode: languageCode(),
    );
    final updated = CaptureInboxEntry(
      id: entry.id,
      packageName: entry.packageName,
      appLabel: entry.appLabel,
      text: entry.text,
      capturedAt: entry.capturedAt,
      draft: composed.draft,
      possibleDuplicate: entry.possibleDuplicate,
      icon: entry.icon,
    );
    inbox[index] = updated;
    await store.saveInbox(inbox);
    changes?.notify();
    return updated;
  }
}
