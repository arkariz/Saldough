import 'dart:async';
import 'dart:typed_data';

import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/active_capture_inputs.dart';
import 'package:saldough/features/notification_capture/domain/services/auto_record_policy.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_draft_composer.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_text.dart';
import 'package:saldough/features/notification_capture/domain/services/transaction_from_draft.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
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
/// - Tidak pernah kehilangan tangkapan: yang di-*ack* hanya tangkapan yang
///   simpanannya berhasil; galat simpan menghentikan putaran dan sisanya
///   tetap di antrean native (ADR-032 §10).
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
    this.sourceIcons,
    this.recurringRules,
    this.matchLog,
    this.recurringChanges,
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

  /// Penyimpanan ikon notifikasi asal (ADR-032 §3.10); `null` = tanpa ikon.
  final SourceIconRepository? sourceIcons;

  /// Rutin untuk tautan otomatis (ADR-035 §3.4); `null` = tanpa pencocokan.
  final RecurringRuleRepository? recurringRules;

  /// Log tautan otomatis (7 hari, Lepaskan).
  final RecurrenceMatchLogRepository? matchLog;

  /// Sinyal rutin berubah, sesudah ada yang tertaut.
  final RecurringChanges? recurringChanges;

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

    final wallets = await loadActiveWallets(walletRepository);
    final patterns = await loadActivePatterns(store, settings);
    final policy = AutoRecordPolicy(settings.autoRecordLevel);
    final rules = (await recurringRules?.listRules())?.getOrElse((_) => const []) ?? const <RecurringRule>[];
    var linkedAny = false;
    final ledgers = <String, List<Transaction>>{};
    final recorded = <AutoRecordedEntry>[];
    final queued = <CaptureInboxEntry>[];
    final handled = <String>[];

    for (final notification in [...pending]..sort((a, b) => a.postedAt.compareTo(b.postedAt))) {
      if (processed.containsKey(notification.id)) {
        handled.add(notification.id);
        continue;
      }
      processed[notification.id] = now;
      final source = settings.activeSource(notification.packageName);
      final text = notification.text;
      if (source == null || NotificationText.looksLikeOtp(text) || !source.matchesKeywords(text)) {
        if (!await _save(processed, inbox, auto)) break;
        handled.add(notification.id);
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
      // Ikon disimpan sekali per isi; id-nya ikut draf, item kotak masuk,
      // dan transaksi (ADR-032 §3.10).
      final iconId = await _saveIcon(notification.icon);
      final draft = composed.draft.copyWith(sourceIconId: () => iconId);
      final date = draft.date ?? notification.postedAt;
      final ledger = ledgers[_monthKey(date)] ??= (await transactionRepository.listTransactionsInMonth(
        date,
      )).getOrElse((_) => const []);
      final duplicate =
          AutoRecordPolicy.matchesLedger(draft, date, ledger) ||
          _nearbyCapture(draft, notification, inbox: inbox, auto: auto);

      if (composed.autoEligible && !duplicate && policy.allows(draft)) {
        final (entry, linked) = await _record(
          draft,
          notification,
          source.appLabel,
          now,
          rules: rules,
          ledger: await _ledgerAround(date, ledgers),
        );
        linkedAny |= linked;
        if (entry != null) {
          auto.insert(0, entry);
          // Sudah di buku besar walau lognya gagal tersimpan.
          recorded.add(entry);
          ledgers.remove(_monthKey(date));
          if (!await _save(processed, inbox, auto)) break;
          handled.add(notification.id);
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
        iconId: iconId,
        reviewReason: duplicate ? null : policy.reviewReason(draft, autoEligible: composed.autoEligible),
      );
      inbox.insert(0, entry);
      if (!await _save(processed, inbox, auto)) break;
      queued.add(entry);
      handled.add(notification.id);
    }

    await gateway.acknowledge(handled);
    if (linkedAny) recurringChanges?.notifyChanged(source: this);
    return CaptureProcessResult(recorded: recorded, queued: queued);
  }

  /// Transaksi bulan [date] serta bulan sebelum dan sesudahnya, untuk
  /// pencocokan rutin (jendela ±3 hari bisa melintasi bulan).
  Future<List<Transaction>> _ledgerAround(DateTime date, Map<String, List<Transaction>> ledgers) async {
    final result = <Transaction>[];
    for (final offset in const [-1, 0, 1]) {
      final month = DateTime(date.year, date.month + offset);
      result.addAll(
        ledgers[_monthKey(month)] ??= (await transactionRepository.listTransactionsInMonth(
          month,
        )).getOrElse((_) => const []),
      );
    }
    return result;
  }

  Future<String?> _saveIcon(Uint8List? png) async {
    final repository = sourceIcons;
    if (png == null || repository == null) return null;
    return (await repository.save(png)).fold((_) => null, (id) => id);
  }

  /// Mencatat draf; bila cocok persis dengan tepat satu kemunculan rutin
  /// dan tidak ada transaksi lain yang juga cocok, transaksinya langsung
  /// tertaut (`linkedBy: auto`, KT-R11) dan masuk log tautan. Mengembalikan
  /// entri log otomatis dan apakah ada yang tertaut.
  Future<(AutoRecordedEntry?, bool)> _record(
    RecordDraft draft,
    CapturedNotification notification,
    String appLabel,
    DateTime now, {
    required List<RecurringRule> rules,
    required List<Transaction> ledger,
  }) async {
    var transaction = transactionFromDraft(draft, id: _newId(), fallbackDate: notification.postedAt);
    if (transaction == null) return (null, false);
    final match = rules.isEmpty ? null : matchOccurrences(transaction, rules: rules, transactions: ledger);
    final autoLink = match != null && match.exact && matchCandidates(match.rule, match.date, ledger).isEmpty;
    if (autoLink) transaction = transaction.withRecurrence(match.link(linkedBy: RecurrenceLinkedBy.auto));
    final result = await recordTransaction(transaction, source: this);
    if (result.isLeft()) return (null, false);
    if (autoLink) {
      AppAnalytics.log(RecurringEvents.occurrenceLinkedAuto);
      AppAnalytics.log(PeriodEvents.recurrenceDateGap(transaction.date, match.date));
      await matchLog?.add(
        RecurrenceMatchEntry(
          transactionId: transaction.id,
          transactionDate: transaction.date,
          ruleId: match.rule.id,
          ruleName: match.rule.note,
          occurrenceDate: match.date,
          amount: transaction.amount,
          matchedAt: now,
        ),
      );
    }
    return (_autoEntry(transaction, draft, notification, appLabel, now), autoLink);
  }

  AutoRecordedEntry _autoEntry(
    Transaction transaction,
    RecordDraft draft,
    CapturedNotification notification,
    String appLabel,
    DateTime now,
  ) {
    return AutoRecordedEntry(
      captureId: notification.id,
      transactionId: transaction.id,
      transactionDate: transaction.date,
      kind: draft.kind,
      amountSen: transaction.amount,
      appLabel: appLabel,
      recordedAt: now,
      note: transaction.note,
      categoryId: transaction.categoryId,
      iconId: draft.sourceIconId,
      capturedAt: notification.postedAt,
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
        auto.any(
          (e) => e.captureId != notification.id && e.amountSen == amount && near(e.capturedAt ?? e.transactionDate),
        );
  }

  /// `true` bila ketiganya tersimpan. Kotak masuk dan log lebih dulu: id
  /// terproses yang tersimpan tanpa itemnya berarti tangkapan hilang.
  Future<bool> _save(
    Map<String, DateTime> processed,
    List<CaptureInboxEntry> inbox,
    List<AutoRecordedEntry> auto,
  ) async {
    if ((await store.saveInbox(inbox)).isLeft()) return false;
    if ((await store.saveAutoRecorded(auto)).isLeft()) return false;
    return (await store.saveProcessedIds(processed)).isRight();
  }

  static String _monthKey(DateTime d) => '${d.year}-${d.month}';
}
