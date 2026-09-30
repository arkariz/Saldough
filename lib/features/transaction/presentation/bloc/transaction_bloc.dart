import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
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
/// pengelompokan tanggal berkali-kali per detik. Aturan saring dan
/// kelompoknya sendiri fungsi murni di `transaction_query.dart` (ADR-030
/// §3.6); bloc ini hanya mengorkestrasi.
final class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  /// Membuat [TransactionBloc].
  TransactionBloc({
    required this._walletRepository,
    required this._transactionRepository,
    required this._recordTransaction,
    required this._budgetItemCatalog,
    required LedgerChanges ledgerChanges,
  }) : super(TransactionState.initial()) {
    on<TransactionStarted>(_onStarted);
    on<TransactionRefreshed>(_onRefreshed);
    // ADR-030 §3.4: transaksi/saldo berubah di layar lain -> muat ulang
    // tanpa kerangka.
    _ledgerSubscription = ledgerChanges.from(this).listen((_) => add(const TransactionRefreshed()));
    on<TransactionMonthChanged>(_onMonthChanged);
    on<TransactionTypeFilterChanged>(_onTypeFilterChanged);
    on<TransactionWalletFilterChanged>(_onWalletFilterChanged);
    on<TransactionCategoryFilterChanged>(_onCategoryFilterChanged);
    on<TransactionSearchChanged>(_onSearchChanged);
    on<TransactionSearchAcrossMonthsRequested>(_onSearchAcrossMonthsRequested);
    on<TransactionUpdated>(_onUpdated);
    on<TransactionDeleted>(_onDeleted);
  }

  late final StreamSubscription<void> _ledgerSubscription;
  final WalletRepository _walletRepository;
  final TransactionRepository _transactionRepository;
  final RecordTransaction _recordTransaction;
  final BudgetItemCatalog _budgetItemCatalog;

  /// Berapa bulan dipindai sekali tekan "Cari di bulan lain"/"Cari lebih
  /// jauh" -- cukup kecil supaya satu ketukan tidak membaca banyak dokumen
  /// bulan sekaligus (NFR-PERF-002), tapi cukup besar supaya riwayat pendek
  /// biasanya habis dalam satu atau dua ketukan.
  static const _crossMonthBatchSize = 3;

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
    final result = await _recordTransaction(event.updated, previousTransaction: event.original, source: this);
    await _afterWrite(result, emit, successEffect: () => _effectSaved(t.transaction.updatedMessage));
  }

  Future<void> _onDeleted(TransactionDeleted event, Emitter<TransactionState> emit) async {
    final result = await _recordTransaction.delete(event.transaction, source: this);
    // UX-8: bukan dialog konfirmasi lagi -- hapus langsung, dengan snackbar
    // "Urungkan" sebagai jalan pulih.
    await _afterWrite(result, emit, successEffect: () => _effectDeletedWithUndo(event.transaction));
  }

  /// Sesudah sunting/hapus/urungkan: kalau gagal, pertahankan layar apa
  /// adanya dan tampilkan galat; kalau berhasil, muat ulang dompet DAN
  /// transaksi bulan ini (saldo dompet berubah, jadi "saldo saat ini" di
  /// layar rincian harus ikut segar) TANPA `isLoading` -- daftar tidak boleh
  /// berkedip jadi kerangka pemuatan tiap kali satu baris disunting.
  Future<void> _afterWrite(
    Either<Failure, Unit> result,
    Emitter<TransactionState> emit, {
    required UiEffect Function() successEffect,
  }) async {
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
            if (!state.loadFailed) emit(state.copyWith(effect: successEffect()));
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
        categoryFilter: event.categoryId,
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

  /// Melanjutkan pencarian lintas bulan (T-8.2): memindai [_crossMonthBatchSize]
  /// bulan berikutnya sebelum [TransactionState.month] yang belum dipindai,
  /// menyaringnya dengan filter/kata kunci AKTIF, lalu menambah hasilnya ke
  /// [TransactionState.crossMonthGroups]. Tidak pernah memanggil
  /// `listAllTransactions()` -- hanya membuka dokumen bulan yang benar-benar
  /// akan dipindai batch ini, satu per satu lewat [TransactionRepository.listTransactionsInMonth].
  Future<void> _onSearchAcrossMonthsRequested(
    TransactionSearchAcrossMonthsRequested event,
    Emitter<TransactionState> emit,
  ) async {
    if (state.searchQuery.trim().isEmpty) return;
    if (state.crossMonthExhausted || state.isSearchingCrossMonth) return;

    // Jepret kriteria saat ini -- kalau berubah sebelum pemindaian batch ini
    // selesai (`_recomputed` lain sudah jalan lebih dulu dan mereset field
    // lintas bulan), hasil batch ini dibuang di akhir, bukan ditimpakan ke
    // kriteria yang sudah tidak berlaku.
    final month = state.month;
    final typeFilter = state.typeFilter;
    final walletFilter = state.walletFilter;
    final categoryFilter = state.categoryFilter;
    final searchQuery = state.searchQuery;

    emit(state.copyWith(isSearchingCrossMonth: true));

    var availableMonths = state.availableMonths;
    if (availableMonths.isEmpty) {
      final monthsResult = await _transactionRepository.listAvailableMonths();
      switch (monthsResult) {
        case Left(value: final failure):
          emit(state.copyWith(isSearchingCrossMonth: false, effect: _effectError(failure)));
          return;
        case Right(value: final months):
          availableMonths = months;
      }
    }

    bool sameCriteria() =>
        state.month == month &&
        state.typeFilter == typeFilter &&
        state.walletFilter == walletFilter &&
        state.categoryFilter == categoryFilter &&
        state.searchQuery == searchQuery;

    final candidates = availableMonths.where((m) => m.isBefore(month)).toList()
      ..sort((a, b) => b.compareTo(a));
    final alreadyScanned = state.crossMonthScannedMonths;
    final remaining = candidates.where((m) => !alreadyScanned.contains(m)).toList();
    final batch = remaining.take(_crossMonthBatchSize).toList();

    if (batch.isEmpty) {
      if (sameCriteria()) {
        emit(state.copyWith(availableMonths: availableMonths, isSearchingCrossMonth: false, crossMonthExhausted: true));
      }
      return;
    }

    final walletNames = _walletNames(state.wallets);
    final matches = [for (final group in state.crossMonthGroups) ...group.transactions];

    for (final monthToScan in batch) {
      final result = await _transactionRepository.listTransactionsInMonth(monthToScan);
      switch (result) {
        case Left(value: final failure):
          if (sameCriteria()) {
            emit(state.copyWith(availableMonths: availableMonths, isSearchingCrossMonth: false, effect: _effectError(failure)));
          }
          return;
        case Right(value: final transactions):
          matches.addAll(
            filterTransactions(
              transactions,
              categoryName: _categoryName,
              walletNames: walletNames,
              walletId: walletFilter,
              categoryId: categoryFilter,
              query: searchQuery,
              type: typeFilter,
            ),
          );
      }
    }

    if (!sameCriteria()) return;

    final scanned = [...alreadyScanned, ...batch];
    emit(
      state.copyWith(
        availableMonths: availableMonths,
        crossMonthScannedMonths: scanned,
        crossMonthGroups: groupTransactionsByDate(matches),
        isSearchingCrossMonth: false,
        crossMonthExhausted: scanned.length >= candidates.length,
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
    // Angka chip jenis dihitung SEBELUM penyaring jenis diterapkan, supaya
    // tiap chip menunjukkan berapa yang akan tampil kalau dipilih.
    final walletCategoryFiltered = filterTransactions(
      rawTransactions,
      categoryName: _categoryName,
      walletNames: _walletNames(wallets),
      walletId: walletFilter,
      categoryId: categoryFilter,
      query: searchQuery,
    );
    final fullyFiltered = [
      for (final transaction in walletCategoryFiltered)
        if (matchesTransactionType(transaction, typeFilter)) transaction,
    ];

    return TransactionState(
      month: month,
      wallets: wallets,
      budgetItems: state.budgetItems,
      rawTransactions: rawTransactions,
      typeFilter: typeFilter,
      walletFilter: walletFilter,
      categoryFilter: categoryFilter,
      categoryOptions: distinctCategoryIds(rawTransactions, categoryName: _categoryName),
      searchQuery: searchQuery,
      groups: groupTransactionsByDate(fullyFiltered),
      typeCounts: countTransactionsByType(walletCategoryFiltered),
      isLoading: false,
    );
  }

  static String? _categoryName(String id) => ActiveCategories.byId(id)?.name;

  static Map<String, String> _walletNames(List<Wallet> wallets) => {for (final wallet in wallets) wallet.id: wallet.name};

  @override
  Future<void> close() async {
    await _ledgerSubscription.cancel();
    return super.close();
  }
}
