import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/account_hint.dart';
import 'package:saldough/features/notification_capture/domain/services/active_capture_inputs.dart';
import 'package:saldough/features/notification_capture/domain/services/approved_shapes.dart';
import 'package:saldough/features/notification_capture/domain/services/auto_record_policy.dart';
import 'package:saldough/features/notification_capture/domain/services/budget_item_suggestion.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_finalizer.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_resolver.dart';
import 'package:saldough/features/notification_capture/domain/services/negative_shapes.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_draft_composer.dart';
import 'package:saldough/features/notification_capture/domain/services/store_backed_merchant_memory.dart';
import 'package:saldough/features/notification_capture/domain/services/transaction_from_draft.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
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
    this.merchantMemory,
    this.negativeShapes,
    this.approvedShapes,
    this.budgetItems,
    this.changes,
    this.recurringRules,
    this.matchLog,
    this.recurringChanges,
    this.finalizer = const CaptureFinalizer(),
    String Function()? newId,
  }) : _newId = newId ?? _timestampId;

  /// Bentuk yang disetujui dicatat otomatis (E3); `null` = tanpa tawaran.
  final StoreBackedApprovedShapes? approvedShapes;

  /// Katalog pos anggaran untuk saran pos (E2); `null` = tanpa saran.
  final BudgetItemCatalog? budgetItems;

  /// Sinyal perubahan kotak masuk, atau `null`.
  final CaptureInboxChanges? changes;

  /// Ingatan pedagang (E1); `null` = tidak belajar.
  final StoreBackedMerchantMemory? merchantMemory;

  /// Bentuk yang bukan transaksi (E1); `null` = tidak belajar.
  final StoreBackedNegativeShapes? negativeShapes;

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

  /// "Bukan transaksi": menutup kartu dan mempelajari bentuk teksnya supaya yang
  /// seperti ini tidak muncul lagi (E1). Mengembalikan fungsi Batalkan (kartu
  /// kembali dan bentuknya dilupakan), atau `null` bila tidak ada yang bisa
  /// dipelajari dari teks itu (kartu tetap tertutup tanpa belajar).
  Future<Future<void> Function()?> markNotTransaction(CaptureInboxEntry entry) async {
    await remove(entry.id);
    final forget = await negativeShapes?.add(packageName: entry.packageName, text: entry.text);
    if (forget == null) return null;
    return () async {
      await forget();
      await restore(entry);
    };
  }

  /// Belajar dompet dari kartu yang dicatat lewat CATAT (E1, banyak dompet tanpa
  /// formulir): bila dompet akhir [walletId] berbeda dari draf kartu dan teksnya
  /// memuat tepat satu pengenal rekening ([accountHintOf]), pengenal itu menjadi
  /// aturan dompet sumber ini. Mengembalikan fungsi Batalkan dan nama pengenal,
  /// atau `null` bila tidak ada yang dipelajari (transfer, dompet sama, tanpa
  /// pengenal, atau sumber tidak ditemukan).
  Future<({String hint, Future<void> Function() undo})?> rememberWallet(
    CaptureInboxEntry entry, {
    required String? walletId,
  }) async {
    if (walletId == null || entry.draft.kind == DraftKind.transfer || walletId == entry.draft.walletId) return null;
    final hint = accountHintOf(entry.text);
    if (hint == null) return null;
    final before = (await store.loadSettings()).fold((_) => null, (value) => value);
    final source = before?.sources.where((s) => s.packageName == entry.packageName).firstOrNull;
    if (before == null || source == null) return null;
    // Pengenal ini hanya milik satu dompet: dicabut dari aturan lain, lalu ditambahkan.
    final rules = <WalletRule>[];
    var added = false;
    for (final rule in source.walletRules) {
      final keywords = [
        for (final k in rule.keywords)
          if (k.trim().toLowerCase() != hint) k,
      ];
      if (rule.walletId == walletId) {
        rules.add(rule.copyWith(keywords: [...keywords, hint]));
        added = true;
      } else if (keywords.isNotEmpty) {
        rules.add(rule.copyWith(keywords: keywords));
      }
    }
    if (!added) rules.add(WalletRule(walletId: walletId, keywords: [hint]));
    final after = NotificationCaptureSettings(
      enabled: before.enabled,
      delivery: before.delivery,
      autoRecordLevel: before.autoRecordLevel,
      disabledBuiltInPatternIds: before.disabledBuiltInPatternIds,
      saveSamples: before.saveSamples,
      sources: [
        for (final s in before.sources)
          if (s.packageName == entry.packageName) s.copyWith(walletRules: rules) else s,
      ],
    );
    if ((await store.saveSettings(after)).isLeft()) return null;
    return (hint: hint, undo: () async => store.saveSettings(before));
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

  /// Belajar dari kartu yang dicatat lewat CATAT: bila kategori akhir
  /// [categoryId] baru atau berbeda dari draf kartu, ingat untuk catatan
  /// [note] dari aplikasi kartu itu. Mengembalikan fungsi Batalkan, atau
  /// `null` bila tidak ada yang dipelajari (transfer, tanpa kategori atau
  /// catatan, kategori sama dengan draf kartu).
  Future<Future<void> Function()?> rememberCategory(
    CaptureInboxEntry entry, {
    required String? categoryId,
    required String note,
  }) async {
    final memory = merchantMemory;
    if (memory == null || categoryId == null || entry.draft.kind == DraftKind.transfer) return null;
    if (normalizeMerchant(note).isEmpty || categoryId == entry.draft.categoryId) return null;
    final previous = await memory.remember(packageName: entry.packageName, note: note, categoryId: categoryId);
    return () => memory.restore(packageName: entry.packageName, note: note, previous: previous);
  }

  /// Tawaran "Catat otomatis yang seperti ini?" (E3) sesudah kartu [entry]
  /// disimpan lewat CATAT. Syarat: jenis, dompet, dan nominal tidak diubah dari
  /// draf kartu (kategori boleh), semua sisi terpetakan, bukan transfer, dan
  /// bentuknya belum disetujui. Mengembalikan templat bentuk (untuk pratinjau
  /// "Seperti: ..."), atau `null` bila tidak ada tawaran.
  Future<String?> autoOfferFor(
    CaptureInboxEntry entry, {
    required DraftKind? savedKind,
    required int? savedAmountSen,
    required String? savedWalletId,
  }) async {
    final shapes = approvedShapes;
    final draft = entry.draft;
    if (shapes == null || draft.kind == DraftKind.transfer || draft.amountSen == null || draft.walletId == null) {
      return null;
    }
    if (savedKind != draft.kind || savedAmountSen != draft.amountSen || savedWalletId != draft.walletId) return null;
    await shapes.refresh();
    if (shapes.isApproved(entry.packageName, entry.text)) return null;
    return approvedTemplateFor(entry.text, draft.note);
  }

  /// Menyetujui bentuk kartu [entry] untuk dicatat otomatis (E3); nominal
  /// [amountSen] jadi contoh pertama pagar nominal. Fungsi Batalkan, atau `null`
  /// bila bentuknya tidak bisa dibuat.
  Future<Future<void> Function()?> approveShape(CaptureInboxEntry entry, {required int? amountSen}) async {
    final shapes = approvedShapes;
    final amount = amountSen;
    if (shapes == null || amount == null) return null;
    AppAnalytics.log(CaptureEvents.shapeApproved);
    return shapes.approve(
      packageName: entry.packageName,
      text: entry.text,
      note: entry.draft.note,
      amountSen: amount,
    );
  }

  /// Belajar pos anggaran dari kartu yang dicatat (E2): pos yang dipilih untuk
  /// catatan kartu itu diingat (nama, bukan id) bila berbeda dari yang disarankan.
  /// Mengembalikan fungsi Batalkan, atau `null` bila tidak ada yang dipelajari.
  Future<({String name, Future<void> Function() undo})?> rememberBudgetItem(
    CaptureInboxEntry entry, {
    required String? budgetItemId,
    required String? suggestedItemId,
  }) async {
    final memory = merchantMemory;
    final catalog = budgetItems;
    final note = entry.draft.note;
    if (memory == null || catalog == null || budgetItemId == null || budgetItemId == suggestedItemId) return null;
    if (entry.draft.kind != DraftKind.expense || normalizeMerchant(note).isEmpty) return null;
    final options = (await catalog.listOptions()).getOrElse((_) => const []);
    final chosen = options.where((o) => o.itemId == budgetItemId && !o.isTransfer).firstOrNull;
    if (chosen == null) return null;
    final previous = await memory.rememberBudget(
      packageName: entry.packageName,
      note: note,
      budgetName: chosen.itemName,
    );
    return (
      name: chosen.itemName,
      undo: () => memory.restoreBudget(packageName: entry.packageName, note: note, previous: previous),
    );
  }

  /// Saran pos anggaran (E2/B-86) per id kartu, hanya untuk pengeluaran yang
  /// tidak cocok dengan rutin (pos rutin diisi `CaptureFinalizer`). Tidak
  /// pernah diisi diam-diam: hanya label di kartu dan isian awal CATAT.
  Future<Map<String, BudgetItemOption>> budgetSuggestionsFor(
    List<CaptureInboxEntry> entries,
    Map<String, OccurrenceMatch> matches,
  ) async {
    final catalog = budgetItems;
    if (catalog == null || entries.isEmpty) return const {};
    final options = (await catalog.listOptions()).getOrElse((_) => const []);
    if (options.isEmpty) return const {};
    await merchantMemory?.refresh();
    final result = <String, BudgetItemOption>{};
    for (final entry in entries) {
      if (matches.containsKey(entry.id)) continue;
      final suggestion = suggestBudgetItem(
        draft: entry.draft,
        date: entry.draft.date ?? entry.capturedAt,
        text: entry.text,
        options: options,
        rememberedName: merchantMemory?.budgetNameFor(packageName: entry.packageName, note: entry.draft.note),
      );
      if (suggestion != null) result[entry.id] = suggestion;
    }
    return result;
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
      if (draft.amountSen == null || draft.walletId == null) continue;
      final date = draft.date ?? entry.capturedAt;
      // Penentu bersama: pola terikat menentukan rutinnya sendiri, selain itu
      // kandidat tunggal (atau yang namanya muncul di teks); ambigu tanpa saran.
      final plan = resolvePlan(
        draft: draft,
        date: date,
        packageName: entry.packageName,
        text: entry.text,
        rules: rules,
        ledger: await around(date),
        patternId: entry.patternId,
      );
      if (plan.match case final match?) result[entry.id] = match;
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
    final built = transactionFromDraft(
      enrichFromPlan(entry.draft, match),
      id: _newId(),
      fallbackDate: entry.capturedAt,
    );
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
