import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/active_capture_inputs.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_draft_composer.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

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
    this.recurringRules,
    this.matchLog,
    this.recurringChanges,
  });

  /// Sinyal perubahan kotak masuk, atau `null`.
  final CaptureInboxChanges? changes;

  /// Rutin untuk label "Cocok dengan rutin" (ADR-035 §3.4); `null` = tanpa.
  final RecurringRuleRepository? recurringRules;

  /// Log tautan otomatis (Lepaskan).
  final RecurrenceMatchLogRepository? matchLog;

  /// Sinyal rutin berubah.
  final RecurringChanges? recurringChanges;

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

  /// Kemunculan rutin yang cocok dengan draf tiap item [entries] (satu
  /// kandidat saja), per id item. Nominal kira-kira dan dompet lain tidak
  /// pernah dicocokkan otomatis; ini hanya saran untuk ditinjau di CATAT.
  Future<Map<String, OccurrenceMatch>> matchesFor(List<CaptureInboxEntry> entries) async {
    final repository = recurringRules;
    if (repository == null || entries.isEmpty) return const {};
    final rules = (await repository.listRules()).getOrElse((_) => const []);
    if (rules.isEmpty) return const {};
    final ledgers = <DateTime, List<Transaction>>{};
    Future<List<Transaction>> around(DateTime date) async => [
      for (final offset in const [-1, 0, 1])
        ...ledgers[DateTime(date.year, date.month + offset)] ??= (await transactionRepository.listTransactionsInMonth(
          DateTime(date.year, date.month + offset),
        )).getOrElse((_) => const []),
    ];
    final result = <String, OccurrenceMatch>{};
    for (final entry in entries) {
      final draft = entry.draft;
      final amount = draft.amountSen;
      final walletId = draft.walletId;
      if (amount == null || walletId == null) continue;
      final date = draft.date ?? entry.capturedAt;
      final candidates = occurrenceCandidates(
        kind: switch (draft.kind) {
          DraftKind.income => RecurringKind.income,
          DraftKind.expense => RecurringKind.expense,
          DraftKind.transfer => RecurringKind.transfer,
        },
        walletId: walletId,
        toWalletId: draft.toWalletId,
        amount: amount,
        date: date,
        rules: rules,
        transactions: await around(date),
      );
      if (candidates.length == 1) result[entry.id] = candidates.single;
    }
    return result;
  }

  /// **Lepaskan** tautan otomatis [entry]: transaksinya tetap, hanya
  /// `recurrence`-nya dikosongkan (saldo tidak berubah), lalu entri log
  /// dihapus. Kemunculannya kembali menunggu.
  Future<Either<Failure, Unit>> unlink(RecurrenceMatchEntry entry) async {
    final ledger = await transactionRepository.listTransactionsInMonth(entry.transactionDate);
    switch (ledger) {
      case Left(:final value):
        return left(value);
      case Right(:final value):
        final transaction = value.where((t) => t.id == entry.transactionId).firstOrNull;
        if (transaction != null && transaction.recurrence != null) {
          final saved = await recordTransaction(transaction.withRecurrence(null), previousTransaction: transaction);
          if (saved.isLeft()) return saved;
          AppAnalytics.log(RecurringEvents.occurrenceUnlinked);
        }
    }
    final removed = await matchLog?.remove(entry.transactionId) ?? right(unit);
    recurringChanges?.notifyChanged();
    changes?.notify();
    return removed;
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
    final wallets = await loadActiveWallets(walletRepository);
    final patterns = await loadActivePatterns(store, settings);
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
      draft: composed.draft.copyWith(sourceIconId: () => entry.iconId),
      possibleDuplicate: entry.possibleDuplicate,
      iconId: entry.iconId,
    );
    inbox[index] = updated;
    await store.saveInbox(inbox);
    changes?.notify();
    return updated;
  }
}
