import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/record/domain/budget_item_catalog.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'transaction_effect.dart';
part 'transaction_event.dart';

/// Bloc layar riwayat transaksi (FR-TXN-004) -- memuat transaksi bulan
/// berjalan lewat `TransactionRepository.listTransactionsInMonth` (buku besar
/// dipartisi per bulan, ADR-012; TIDAK pernah `listAllTransactions()`, itu
/// reserved untuk penghitungan ulang saldo) dan dompet lewat
/// `WalletRepository.listWallets`, lalu menyaring dan mengelompokkannya per
/// tanggal.
///
/// Penyaringan/pengelompokan dihitung SEKALI tiap kali salah satu inputnya
/// berubah (bulan, atau salah satu filter) lewat [_recomputed] -- bukan di
/// widget tiap `build()` -- supaya berpindah tab tidak menghitung ulang
/// pengelompokan tanggal berkali-kali per detik.
final class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  /// Membuat [TransactionBloc].
  TransactionBloc({
    required this._walletRepository,
    required this._transactionRepository,
    required this._recordTransaction,
    required this._budgetItemCatalog,
  }) : super(TransactionState.initial()) {
    on<TransactionStarted>(_onStarted);
    on<TransactionRefreshed>(_onRefreshed);
    on<TransactionMonthChanged>(_onMonthChanged);
    on<TransactionTypeFilterChanged>(_onTypeFilterChanged);
    on<TransactionWalletFilterChanged>(_onWalletFilterChanged);
    on<TransactionCategoryFilterChanged>(_onCategoryFilterChanged);
    on<TransactionSearchChanged>(_onSearchChanged);
    on<TransactionUpdated>(_onUpdated);
    on<TransactionDeleted>(_onDeleted);
  }

  final WalletRepository _walletRepository;
  final TransactionRepository _transactionRepository;
  final RecordTransaction _recordTransaction;
  final BudgetItemCatalog _budgetItemCatalog;

  /// Memuat pos anggaran (data sekunder — gagal berarti daftar kosong, tidak
  /// menghalangi riwayat tampil).
  Future<void> _loadBudgetItems(Emitter<TransactionState> emit) async {
    final items = (await _budgetItemCatalog.listOptions()).getOrElse((_) => const []);
    emit(state.copyWith(budgetItems: items));
  }

  Future<void> _onStarted(TransactionStarted event, Emitter<TransactionState> emit) async {
    emit(state.copyWith(isLoading: true, loadFailed: false));
    final walletsResult = await _walletRepository.listWallets();
    switch (walletsResult) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, loadFailed: true, effect: _effectError(failure)));
      case Right(value: final wallets):
        await _loadBudgetItems(emit);
        await _loadMonth(month: state.month, wallets: wallets, emit: emit);
    }
  }

  Future<void> _onRefreshed(TransactionRefreshed event, Emitter<TransactionState> emit) async {
    final walletsResult = await _walletRepository.listWallets();
    switch (walletsResult) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right(value: final wallets):
        await _loadBudgetItems(emit);
        await _loadMonth(month: state.month, wallets: wallets, emit: emit);
    }
  }

  Future<void> _onUpdated(TransactionUpdated event, Emitter<TransactionState> emit) async {
    final result = await _recordTransaction(event.updated, previousTransaction: event.original);
    await _afterWrite(result, t.transaction.updatedMessage, emit);
  }

  Future<void> _onDeleted(TransactionDeleted event, Emitter<TransactionState> emit) async {
    final result = await _recordTransaction.delete(event.transaction);
    await _afterWrite(result, t.transaction.deletedMessage, emit);
  }

  /// Sesudah sunting/hapus: kalau gagal, pertahankan layar apa adanya dan
  /// tampilkan galat; kalau berhasil, muat ulang dompet DAN transaksi bulan
  /// ini (saldo dompet berubah, jadi "saldo saat ini" di layar rincian harus
  /// ikut segar) TANPA `isLoading` -- daftar tidak boleh berkedip jadi
  /// kerangka pemuatan tiap kali satu baris disunting.
  Future<void> _afterWrite(Either<Failure, Unit> result, String successMessage, Emitter<TransactionState> emit) async {
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        final walletsResult = await _walletRepository.listWallets();
        switch (walletsResult) {
          case Left(value: final failure):
            emit(state.copyWith(effect: _effectError(failure)));
          case Right(value: final wallets):
            await _loadMonth(month: state.month, wallets: wallets, emit: emit);
            if (!state.loadFailed) emit(state.copyWith(effect: _effectSaved(successMessage)));
        }
    }
  }

  Future<void> _onMonthChanged(TransactionMonthChanged event, Emitter<TransactionState> emit) async {
    emit(state.copyWith(isLoading: true, loadFailed: false, month: event.month));
    await _loadMonth(month: event.month, wallets: state.wallets, emit: emit);
  }

  Future<void> _loadMonth({
    required DateTime month,
    required List<Wallet> wallets,
    required Emitter<TransactionState> emit,
  }) async {
    final result = await _transactionRepository.listTransactionsInMonth(month);
    switch (result) {
      case Left(value: final failure):
        emit(
          state.copyWith(
            month: month,
            wallets: wallets,
            isLoading: false,
            loadFailed: true,
            effect: _effectError(failure),
          ),
        );
      case Right(value: final transactions):
        emit(
          _recomputed(
            month: month,
            wallets: wallets,
            rawTransactions: transactions,
            typeFilter: state.typeFilter,
            walletFilter: state.walletFilter,
            categoryFilter: state.categoryFilter,
            searchQuery: state.searchQuery,
          ),
        );
    }
  }

  void _onTypeFilterChanged(TransactionTypeFilterChanged event, Emitter<TransactionState> emit) {
    emit(
      _recomputed(
        month: state.month,
        wallets: state.wallets,
        rawTransactions: state.rawTransactions,
        typeFilter: event.filter,
        walletFilter: state.walletFilter,
        categoryFilter: state.categoryFilter,
        searchQuery: state.searchQuery,
      ),
    );
  }

  void _onWalletFilterChanged(TransactionWalletFilterChanged event, Emitter<TransactionState> emit) {
    emit(
      _recomputed(
        month: state.month,
        wallets: state.wallets,
        rawTransactions: state.rawTransactions,
        typeFilter: state.typeFilter,
        walletFilter: event.walletId,
        categoryFilter: state.categoryFilter,
        searchQuery: state.searchQuery,
      ),
    );
  }

  void _onCategoryFilterChanged(TransactionCategoryFilterChanged event, Emitter<TransactionState> emit) {
    emit(
      _recomputed(
        month: state.month,
        wallets: state.wallets,
        rawTransactions: state.rawTransactions,
        typeFilter: state.typeFilter,
        walletFilter: state.walletFilter,
        categoryFilter: event.categoryKey,
        searchQuery: state.searchQuery,
      ),
    );
  }

  void _onSearchChanged(TransactionSearchChanged event, Emitter<TransactionState> emit) {
    emit(
      _recomputed(
        month: state.month,
        wallets: state.wallets,
        rawTransactions: state.rawTransactions,
        typeFilter: state.typeFilter,
        walletFilter: state.walletFilter,
        categoryFilter: state.categoryFilter,
        searchQuery: event.query,
      ),
    );
  }

  /// Membangun [TransactionState] baru langsung lewat konstruktor (bukan
  /// [TransactionState.copyWith]) -- satu-satunya cara [walletFilter]/
  /// [categoryFilter] bisa dikembalikan ke `null` ("Semua"), sesuatu yang
  /// `copyWith` gaya `?? this.x` di seluruh basis kode ini sengaja tidak
  /// mendukung (lihat catatan `ExpenseTransaction.copyWith` soal
  /// `budgetItemId`).
  TransactionState _recomputed({
    required DateTime month,
    required List<Wallet> wallets,
    required List<Transaction> rawTransactions,
    required TransactionTypeFilter typeFilter,
    required String? walletFilter,
    required String? categoryFilter,
    required String searchQuery,
  }) {
    final categoryOptions = _distinctCategories(rawTransactions);

    final needle = searchQuery.trim().toLowerCase();
    final walletNames = {for (final wallet in wallets) wallet.id: wallet.name.toLowerCase()};

    final walletCategoryFiltered = rawTransactions.where((transaction) {
      if (walletFilter != null && !_walletIdsOf(transaction).contains(walletFilter)) return false;
      if (categoryFilter != null && transaction.categoryKey != categoryFilter) return false;
      if (needle.isNotEmpty && !_matchesSearch(transaction, needle, walletNames)) return false;
      return true;
    }).toList();

    final typeCounts = <TransactionTypeFilter, int>{
      TransactionTypeFilter.all: walletCategoryFiltered.length,
      TransactionTypeFilter.income: walletCategoryFiltered.whereType<IncomeTransaction>().length,
      TransactionTypeFilter.expense: walletCategoryFiltered.whereType<ExpenseTransaction>().length,
      TransactionTypeFilter.transfer: walletCategoryFiltered.whereType<TransferTransaction>().length,
    };

    final fullyFiltered = walletCategoryFiltered.where((transaction) => _matchesType(transaction, typeFilter)).toList();

    return TransactionState(
      month: month,
      wallets: wallets,
      budgetItems: state.budgetItems,
      rawTransactions: rawTransactions,
      typeFilter: typeFilter,
      walletFilter: walletFilter,
      categoryFilter: categoryFilter,
      categoryOptions: categoryOptions,
      searchQuery: searchQuery,
      groups: _groupByDate(fullyFiltered),
      typeCounts: typeCounts,
      isLoading: false,
    );
  }

  /// Cocok kalau [needle] (sudah huruf kecil) muncul di kategori, catatan,
  /// atau nama salah satu dompet yang disentuh [transaction].
  bool _matchesSearch(Transaction transaction, String needle, Map<String, String> walletNames) {
    if ((transaction.categoryKey ?? '').toLowerCase().contains(needle)) return true;
    if (transaction.note.toLowerCase().contains(needle)) return true;
    return _walletIdsOf(transaction).any((id) => (walletNames[id] ?? '').contains(needle));
  }

  bool _matchesType(Transaction transaction, TransactionTypeFilter filter) => switch (filter) {
    TransactionTypeFilter.all => true,
    TransactionTypeFilter.income => transaction is IncomeTransaction,
    TransactionTypeFilter.expense => transaction is ExpenseTransaction,
    TransactionTypeFilter.transfer => transaction is TransferTransaction,
  };

  /// Dompet yang tersentuh oleh [transaction] -- satu untuk pemasukan/
  /// pengeluaran, dua untuk transfer. Dipakai supaya menyaring dompet "BCA"
  /// juga menampilkan transfer yang menyentuh BCA sebagai asal ATAU tujuan.
  Set<String> _walletIdsOf(Transaction transaction) => switch (transaction) {
    IncomeTransaction() => {transaction.walletId},
    ExpenseTransaction() => {transaction.walletId},
    TransferTransaction() => {transaction.fromWalletId, transaction.toWalletId},
  };

  List<String> _distinctCategories(List<Transaction> transactions) {
    final keys = <String>{};
    for (final transaction in transactions) {
      final key = transaction.categoryKey;
      if (key != null && key.isNotEmpty) keys.add(key);
    }
    return keys.toList()..sort();
  }

  List<TransactionDateGroup> _groupByDate(List<Transaction> transactions) {
    final byDay = <DateTime, List<Transaction>>{};
    for (final transaction in transactions) {
      final day = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      byDay.putIfAbsent(day, () => []).add(transaction);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final day in days)
        TransactionDateGroup(
          date: day,
          netSen: _netSenOf(byDay[day]!),
          transactions: byDay[day]!..sort((a, b) => b.date.compareTo(a.date)),
        ),
    ];
  }

  /// Pemasukan dikurangi pengeluaran pada satu tanggal. Transfer TIDAK ikut
  /// dihitung (CLAUDE.md aturan 7 -- transfer tidak pernah terhitung sebagai
  /// pemasukan maupun pengeluaran).
  int _netSenOf(List<Transaction> transactions) {
    var net = 0;
    for (final transaction in transactions) {
      switch (transaction) {
        case IncomeTransaction():
          net += transaction.amount;
        case ExpenseTransaction():
          net -= transaction.amount;
        case TransferTransaction():
          break;
      }
    }
    return net;
  }
}
