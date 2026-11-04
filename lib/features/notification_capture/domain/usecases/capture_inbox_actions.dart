import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/active_capture_inputs.dart';
import 'package:saldough/features/notification_capture/domain/services/auto_record_policy.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_finalizer.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_draft_composer.dart';
import 'package:saldough/features/notification_capture/domain/services/transaction_from_draft.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Kode galat: draf belum lengkap untuk dicatat satu ketuk.
const incompleteDraftCode = FailureCode('NOTIFICATION_CAPTURE_INCOMPLETE_DRAFT');

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
    this.finalizer = const CaptureFinalizer(),
    String Function()? newId,
  }) : _newId = newId ?? _timestampId;

  /// Sinyal perubahan kotak masuk, atau `null`.
  final CaptureInboxChanges? changes;

  /// Rutin untuk label "Cocok dengan rutin" (ADR-035 §3.4); `null` = tanpa.
  final RecurringRuleRepository? recurringRules;

  /// Log tautan otomatis (Lepaskan).
  final RecurrenceMatchLogRepository? matchLog;

  /// Penutup bersama: tautan rutin dan pos anggaran (ADR-044 §3.2).
  final CaptureFinalizer finalizer;

  final String Function() _newId;

  static String _timestampId() => DateTime.now().microsecondsSinceEpoch.toString();

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

  /// Mengembalikan item [entry] yang baru diabaikan ke kotak masuk
  /// (Urungkan, QA PR #43 F18), urut menurut waktu notifikasi.
  Future<Either<Failure, Unit>> restore(CaptureInboxEntry entry) async {
    final inbox = (await store.loadInbox()).getOrElse((_) => const []);
    if (inbox.any((e) => e.id == entry.id)) return right(unit);
    final saved = await store.saveInbox(
      [...inbox, entry]..sort((a, b) => b.capturedAt.compareTo(a.capturedAt)),
    );
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
      final kind = switch (draft.kind) {
        DraftKind.income => RecurringKind.income,
        DraftKind.expense => RecurringKind.expense,
        DraftKind.transfer => RecurringKind.transfer,
      };
      // Pola yang terikat ke rutin (ADR-042 §3.4) menentukan rutinnya sendiri;
      // bila kemunculannya tidak jelas, tidak ada saran (tidak menebak).
      final bound = entry.patternId == null
          ? null
          : rules
                .where(
                  (r) =>
                      r.notificationBinding?.packageName == entry.packageName &&
                      r.notificationBinding?.patternId == entry.patternId,
                )
                .firstOrNull;
      if (bound != null) {
        final match = matchBoundOccurrence(
          bound,
          kind: kind,
          walletId: walletId,
          toWalletId: draft.toWalletId,
          amount: amount,
          date: date,
          transactions: await around(date),
        );
        if (match != null) result[entry.id] = match;
        continue;
      }
      final candidates = occurrenceCandidates(
        kind: kind,
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
          final saved = await recordTransaction(
            CaptureFinalizer.release(transaction),
            previousTransaction: transaction,
          );
          if (saved.isLeft()) return saved;
          AppAnalytics.log(RecurringEvents.occurrenceUnlinked);
        }
    }
    final removed = await matchLog?.remove(entry.transactionId) ?? right(unit);
    recurringChanges?.notifyChanged();
    changes?.notify();
    return removed;
  }

  /// Transaksi di buku besar yang tampak sama dengan tiap kartu yang menunggu,
  /// per id item (ADR-044 §3.3). Dihitung ulang saat kartu tampil, jadi
  /// transaksi yang dicatat manual sesudah tangkapan masuk tetap terdeteksi.
  /// Satu transaksi hanya dicocokkan ke satu kartu (yang tertua lebih dulu):
  /// dua kopi yang sama di hari yang sama bukan satu catatan. Kartu tidak
  /// pernah ditutup otomatis, karena dua pembelian yang sama bisa sungguhan.
  Future<Map<String, Transaction>> duplicatesFor(List<CaptureInboxEntry> entries) async {
    if (entries.isEmpty) return const {};
    final months = <DateTime, List<Transaction>>{};
    Future<List<Transaction>> monthOf(DateTime date) async =>
        months[DateTime(date.year, date.month)] ??= (await transactionRepository.listTransactionsInMonth(
          date,
        )).getOrElse((_) => const []);
    final result = <String, Transaction>{};
    final used = <String>{};
    final oldestFirst = [...entries]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    for (final entry in oldestFirst) {
      final draft = entry.draft;
      if (draft.amountSen == null || draft.walletId == null) continue;
      final date = draft.date ?? entry.capturedAt;
      final match = AutoRecordPolicy.findInLedger(draft, date, await monthOf(date), exclude: used);
      if (match == null) continue;
      used.add(match.id);
      result[entry.id] = match;
    }
    return result;
  }

  /// Mencatat kartu [entry] satu ketuk (ADR-044 §3.6): transaksi dari draf yang
  /// lengkap, ditautkan ke [match] (dan pos periodenya) bila ada, lewat
  /// `RecordTransaction`, tanpa formulir. Kartu dihapus dari kotak masuk.
  /// Pemanggil menjaga syaratnya (`cardClassOf`, `oneTapAllowed`); draf yang
  /// belum lengkap gagal tanpa menyentuh data.
  Future<Either<Failure, Transaction>> confirm(CaptureInboxEntry entry, {OccurrenceMatch? match}) async {
    final built = transactionFromDraft(entry.draft, id: _newId(), fallbackDate: entry.capturedAt);
    if (built == null) {
      return left(const ValidationFailure(code: incompleteDraftCode, message: 'draf belum lengkap'));
    }
    final transaction = await finalizer.finalize(built, match: match, linkedBy: RecurrenceLinkedBy.user);
    final saved = await recordTransaction(transaction, source: this);
    if (saved case Left(:final value)) return left(value);
    if (match != null) {
      AppAnalytics.log(RecurringEvents.occurrenceLinked);
      recurringChanges?.notifyChanged();
    }
    await remove(entry.id);
    return right(transaction);
  }

  /// Membatalkan [confirm]: transaksi dihapus (saldo kembali) dan kartu
  /// dikembalikan ke kotak masuk.
  Future<Either<Failure, Unit>> undoConfirm(CaptureInboxEntry entry, Transaction transaction) async {
    final deleted = await recordTransaction.delete(transaction);
    if (deleted.isLeft()) return deleted;
    recurringChanges?.notifyChanged();
    return restore(entry);
  }

  /// Menautkan transaksi yang sudah ada ([existing], yang dicatat manual) ke
  /// kemunculan [match] dan pos periodenya, lalu menutup kartu [entryId].
  /// Saldo tidak berubah. Tidak melakukan apa pun bila [existing] sudah
  /// tertaut ke rutin.
  Future<Either<Failure, Unit>> linkExisting(String entryId, Transaction existing, OccurrenceMatch match) async {
    if (existing.recurrence == null) {
      final linked = await finalizer.finalize(existing, match: match, linkedBy: RecurrenceLinkedBy.user);
      final saved = await recordTransaction(linked, previousTransaction: existing);
      if (saved.isLeft()) return saved;
      AppAnalytics.log(RecurringEvents.occurrenceLinked);
      recurringChanges?.notifyChanged();
    }
    return remove(entryId);
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
      reviewReason: entry.reviewReason,
    );
    inbox[index] = updated;
    await store.saveInbox(inbox);
    changes?.notify();
    return updated;
  }
}
