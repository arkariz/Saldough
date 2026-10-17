import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/analysis/domain/category_detail.dart';
import 'package:saldough/features/analysis/domain/period_comparison.dart';
import 'package:saldough/features/analysis/domain/period_trend.dart';
import 'package:saldough/features/analysis/presentation/bloc/category_detail_state.dart';
import 'package:saldough/features/analysis/presentation/navigation/analysis_route_keys.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Paling banyak transaksi yang tampil di Rincian kategori (F4).
const categoryDetailTransactionLimit = 20;

/// Peristiwa [CategoryDetailBloc].
sealed class CategoryDetailEvent {
  /// Membuat [CategoryDetailEvent].
  const CategoryDetailEvent();
}

/// Layar dibuka.
final class CategoryDetailStarted extends CategoryDetailEvent {
  /// Membuat [CategoryDetailStarted].
  const CategoryDetailStarted();
}

/// Muat ulang tanpa kerangka (transaksi, kategori, awal bulan, atau tanggal berubah).
final class CategoryDetailRefreshed extends CategoryDetailEvent {
  /// Membuat [CategoryDetailRefreshed].
  const CategoryDetailRefreshed();
}

/// Memilih kolom tren [index]; hanya memilih, tidak berpindah periode.
final class CategoryDetailTrendSelected extends CategoryDetailEvent {
  /// Membuat [CategoryDetailTrendSelected].
  const CategoryDetailTrendSelected(this.index);

  /// Indeks kolom di `CategoryDetail.trend`.
  final int index;
}

/// Bloc Rincian kategori (FR-ANL-004, F4, B-17): total satu kategori di satu
/// periode, pembanding, frekuensi, tren enam periode, dan transaksinya. Hanya
/// membaca; segar lewat `LedgerChanges`, jadi sekembalinya dari sunting angka
/// dan daftar sudah baru.
///
/// ⚠ Membaca dokumen bulan enam periode ke belakang sekaligus (satu
/// [ListPeriodTransactions]), sama dengan Analisis.
final class CategoryDetailBloc extends Bloc<CategoryDetailEvent, CategoryDetailState> {
  /// Membuat [CategoryDetailBloc] untuk [input]. [categoryOf] dan [now] bisa
  /// diganti di uji.
  CategoryDetailBloc({
    required TransactionRepository transactionRepository,
    required WalletRepository walletRepository,
    required LedgerChanges ledgerChanges,
    required this.input,
    Category? Function(String id)? categoryOf,
    DateTime Function()? now,
  }) : _transactions = transactionRepository,
       _wallets = walletRepository,
       _categoryOf = categoryOf ?? ActiveCategories.byId,
       _now = now ?? DateTime.now,
       super(
         CategoryDetailState(
           period: ActiveFinancialMonth.schedule.periodOf(input.periodStart),
           kind: input.kind,
           isLoading: true,
         ),
       ) {
    on<CategoryDetailStarted>((event, emit) => _load(emit, firstLoad: true));
    on<CategoryDetailRefreshed>((event, emit) => _load(emit, firstLoad: false));
    on<CategoryDetailTrendSelected>((event, emit) {
      final length = state.detail?.trend.length ?? 0;
      if (event.index >= 0 && event.index < length) emit(state.withTrendSelected(event.index));
    });
    _ledgerSubscription = ledgerChanges.from(this).listen((_) => _refresh());
    ActiveFinancialMonth.notifier.addListener(_refresh);
    ActiveDay.notifier.addListener(_refresh);
    ActiveCategories.notifier.addListener(_refresh);
    ActiveCurrency.notifier.addListener(_refresh);
  }

  /// Kategori, periode, jenis, dan dompet yang dirinci.
  final CategoryDetailInput input;

  void _refresh() => add(const CategoryDetailRefreshed());

  late final StreamSubscription<void> _ledgerSubscription;
  final TransactionRepository _transactions;
  final WalletRepository _wallets;
  final Category? Function(String id) _categoryOf;
  final DateTime Function() _now;

  String get _key => input.categoryId == null ? freelanceGroupKey : categoryGroupKey(input.categoryId!);

  Future<void> _load(
    Emitter<CategoryDetailState> emit, {
    required bool firstLoad,
  }) async {
    final schedule = ActiveFinancialMonth.schedule;
    final today = _now();
    final current = schedule.periodOf(today);
    var period = schedule.periodOf(input.periodStart);
    if (period.start.isAfter(current.start)) period = current;

    final (months, wallets) = await (
      _transactions.listAvailableMonths(),
      _wallets.listWallets(),
    ).wait;
    if (months case Left(:final value)) return _fail(emit, value, firstLoad: firstLoad);
    if (wallets case Left(:final value)) return _fail(emit, value, firstLoad: firstLoad);
    final monthList = (months as Right<Failure, List<DateTime>>).value;
    final walletList = (wallets as Right<Failure, List<Wallet>>).value;

    final first = monthList.isEmpty ? period.start : monthList.reduce((a, b) => a.isBefore(b) ? a : b);
    final earliest = schedule.periodOf(DateTime(first.year, first.month));
    final trend = trendPeriods(
      period: period,
      schedule: schedule,
      earliestStart: earliest.start,
    );
    final comparison = comparisonPeriods(
      period: period,
      schedule: schedule,
      earliestStart: earliest.start,
    );

    switch (await ListPeriodTransactions(_transactions)(
      from: trend.first.start,
      until: period.end,
    )) {
      case Left(:final value):
        _fail(emit, value, firstLoad: firstLoad);
      case Right(value: final all):
        final category = input.categoryId == null ? null : _categoryOf(input.categoryId!);
        final detail = summarizeCategory(
          transactions: all,
          period: period,
          trendPeriodList: trend,
          comparisonPeriodList: comparison,
          key: _key,
          kind: input.kind,
          categoryOf: _categoryOf,
          today: today,
          walletId: input.walletId,
          minSen: highlightMinSenOf(ActiveCurrency.value),
        );
        final filter = periodFilter(period);
        final matched =
            [
              for (final transaction in all)
                if (filter.matches(
                  transaction,
                  isKnownCategory: (id) => _categoryOf(id) != null,
                ))
                  transaction,
            ]..sort((a, b) {
              final byDate = b.date.compareTo(a.date);
              return byDate != 0 ? byDate : b.id.compareTo(a.id);
            });
        emit(
          CategoryDetailState(
            period: period,
            kind: input.kind,
            isLoading: false,
            name: input.categoryId == null ? t.analysis.freelanceGroup : (category?.name ?? ''),
            isArchived: category?.isArchived ?? false,
            detail: detail,
            groups: groupTransactionsByDate(
              matched.take(categoryDetailTransactionLimit),
            ),
            wallets: walletList,
            hasMore: matched.length > categoryDetailTransactionLimit,
            trendSelected: firstLoad ? null : state.trendSelected,
          ),
        );
    }
  }

  /// Saringan transaksi kategori ini untuk [period]; juga dipakai "Lihat
  /// semua transaksi", jadi jumlahnya sama dengan total di Rincian.
  PeriodTransactionFilter periodFilter(FinancialPeriod period) => PeriodTransactionFilter(
    from: period.start,
    until: period.end,
    type: input.kind == CategoryKind.expense ? TransactionTypeFilter.expense : TransactionTypeFilter.income,
    categoryId: input.categoryId,
    freelance: input.categoryId == null,
    walletId: input.walletId,
  );

  void _fail(
    Emitter<CategoryDetailState> emit,
    Failure failure, {
    required bool firstLoad,
  }) {
    final effect = ShowSnackBarEffect(
      message: failure.userMessage ?? t.common.genericErrorMessage,
      severity: .error,
    );
    emit(
      firstLoad ? state.copyWith(isLoading: false, loadFailed: true, effect: effect) : state.copyWith(effect: effect),
    );
  }

  @override
  Future<void> close() async {
    ActiveFinancialMonth.notifier.removeListener(_refresh);
    ActiveDay.notifier.removeListener(_refresh);
    ActiveCategories.notifier.removeListener(_refresh);
    ActiveCurrency.notifier.removeListener(_refresh);
    await _ledgerSubscription.cancel();
    return super.close();
  }
}
