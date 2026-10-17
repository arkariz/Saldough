import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/app_action_snack_bar.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'transaction_effect.dart';
part 'transaction_event.dart';

/// Bloc layar riwayat transaksi (FR-TXN-004) -- memuat transaksi satu
/// **periode keuangan** (ADR-038, T-19.10) lewat `ListPeriodTransactions`
/// (dokumen bulan yang disentuh periode ± batas atribusi; buku besar
/// dipartisi per bulan, ADR-012; TIDAK pernah `listAllTransactions()`, itu
/// reserved untuk penghitungan ulang saldo), memakai `periodDateOf` untuk
/// keanggotaan, dan dompet lewat
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
    on<TransactionPeriodStepped>(_onPeriodStepped);
    on<TransactionPeriodSynced>(_onPeriodSynced);
    HistoryPeriod.notifier.addListener(_syncPeriod);
    ActiveFinancialMonth.notifier.addListener(_refresh);
    ActiveDay.notifier.addListener(_refresh);
    on<TransactionTypeFilterChanged>(_onTypeFilterChanged);
    on<TransactionWalletFilterChanged>(_onWalletFilterChanged);
    on<TransactionCategoryFilterChanged>(_onCategoryFilterChanged);
    on<TransactionSearchChanged>(_onSearchChanged);
    on<TransactionSearchAcrossMonthsRequested>(_onSearchAcrossMonthsRequested);
    on<TransactionUpdated>(_onUpdated);
    on<TransactionDeleted>(_onDeleted);
  }

  late final StreamSubscription<void> _ledgerSubscription;

  void _refresh() => add(const TransactionRefreshed());

  void _syncPeriod() => add(const TransactionPeriodSynced());

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
        await _loadPeriod(period: _target(), wallets: wallets, emit: emit);
    }
  }

  Future<void> _onRefreshed(TransactionRefreshed event, Emitter<TransactionState> emit) async {
    final walletsResult = await _walletRepository.listWallets();
    switch (walletsResult) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right(value: final wallets):
        await _loadBudgetItems(emit);
        await _loadPeriod(period: _target(), wallets: wallets, emit: emit);
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
            await _loadPeriod(period: _target(), wallets: wallets, emit: emit);
            if (!state.loadFailed) emit(state.copyWith(effect: successEffect()));
        }
    }
  }

  /// Periode yang harus tampil: yang dipilih bersama (`HistoryPeriod`), atau
  /// periode berjalan. Periode di masa depan tidak pernah tampil.
  FinancialPeriod _target() {
    final schedule = ActiveFinancialMonth.schedule;
    final current = schedule.periodOf(DateTime.now());
    final anchor = HistoryPeriod.anchor;
    if (anchor == null) return current;
    final period = schedule.periodOf(anchor);
    return period.start.isAfter(current.start) ? current : period;
  }

  Future<void> _onPeriodStepped(TransactionPeriodStepped event, Emitter<TransactionState> emit) async {
    final schedule = ActiveFinancialMonth.schedule;
    final shown = state.period;
    if (event.forward) {
      if (state.isCurrent) return;
    } else if (!state.canGoBack) {
      return;
    }
    final target = event.forward ? schedule.nextOf(shown) : schedule.previousOf(shown);
    HistoryPeriod.select(target, schedule.periodOf(DateTime.now()));
    emit(state.copyWith(isLoading: true, loadFailed: false, period: target));
    await _loadPeriod(period: target, wallets: state.wallets, emit: emit);
  }

  Future<void> _onPeriodSynced(TransactionPeriodSynced event, Emitter<TransactionState> emit) async {
    final target = _target();
    if (target.start == state.period.start && target.end == state.period.end) return;
    emit(state.copyWith(isLoading: true, loadFailed: false, period: target));
    await _loadPeriod(period: target, wallets: state.wallets, emit: emit);
  }

  Future<void> _loadPeriod({
    required FinancialPeriod period,
    required List<Wallet> wallets,
    required Emitter<TransactionState> emit,
  }) async {
    final schedule = ActiveFinancialMonth.schedule;
    final current = schedule.periodOf(DateTime.now());
    final monthsResult = await _transactionRepository.listAvailableMonths();
    final months = switch (monthsResult) {
      Right(:final value) => value,
      Left() => state.availableMonths,
    };
    final result = await ListPeriodTransactions(_transactionRepository)(from: period.start, until: period.end);
    switch (result) {
      case Left(value: final failure):
        emit(
          state.copyWith(
            period: period,
            wallets: wallets,
            isLoading: false,
            loadFailed: true,
            effect: _effectError(failure),
          ),
        );
      case Right(value: final transactions):
        final first = months.isEmpty ? null : months.reduce((a, b) => a.isBefore(b) ? a : b);
        final earliest = first == null ? period : schedule.periodOf(DateTime(first.year, first.month));
        final members = [
          for (final transaction in transactions)
            if (period.contains(periodDateOf(transaction))) transaction,
        ];
        // Periode yang dilihat ikut dibagi dengan Analisis; periode berjalan = `null`.
        HistoryPeriod.select(period, current);
        emit(
          _recomputed(
            period: period,
            wallets: wallets,
            rawTransactions: members,
            typeFilter: state.typeFilter,
            walletFilter: state.walletFilter,
            categoryFilter: state.categoryFilter,
            searchQuery: state.searchQuery,
            isCurrent: period.start == current.start,
            canGoBack: period.start.isAfter(earliest.start),
            availableMonths: months,
          ),
        );
    }
  }

  void _onTypeFilterChanged(TransactionTypeFilterChanged event, Emitter<TransactionState> emit) {
    emit(
      _recomputed(
        period: state.period,
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
        period: state.period,
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
        period: state.period,
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
        period: state.period,
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
    final period = state.period;
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
        state.period == period &&
        state.typeFilter == typeFilter &&
        state.walletFilter == walletFilter &&
        state.categoryFilter == categoryFilter &&
        state.searchQuery == searchQuery;

    // Bulan sebelum periode ini; bulan tempat periode dimulai ikut bila periodenya
    // tidak mulai tanggal 1 (isinya sebagian milik periode sebelumnya).
    final startMonth = DateTime(period.start.year, period.start.month);
    final candidates = availableMonths
        .where((m) => m.isBefore(startMonth) || (period.start.day > 1 && m == startMonth))
        .toList()
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
              [
                for (final transaction in transactions)
                  if (periodDateOf(transaction).isBefore(period.start)) transaction,
              ],
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
    required FinancialPeriod period,
    required List<Wallet> wallets,
    required List<Transaction> rawTransactions,
    required TransactionTypeFilter typeFilter,
    required String? walletFilter,
    required String? categoryFilter,
    required String searchQuery,
    bool? isCurrent,
    bool? canGoBack,
    List<DateTime>? availableMonths,
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
      period: period,
      isCurrent: isCurrent ?? state.isCurrent,
      canGoBack: canGoBack ?? state.canGoBack,
      availableMonths: availableMonths ?? state.availableMonths,
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
    HistoryPeriod.notifier.removeListener(_syncPeriod);
    ActiveFinancialMonth.notifier.removeListener(_refresh);
    ActiveDay.notifier.removeListener(_refresh);
    await _ledgerSubscription.cancel();
    return super.close();
  }
}
