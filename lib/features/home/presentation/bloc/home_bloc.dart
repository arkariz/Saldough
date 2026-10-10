import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';
import 'package:saldough/features/home/presentation/bloc/home_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'home_effect.dart';
part 'home_event.dart';

/// Bloc Beranda (FR-HOME-001..005): total saldo, arus periode keuangan
/// berjalan (ADR-038 §3.6), ringkasan anggaran dan freelance lewat port
/// milik `home` (ADR-0009), dan transaksi terbaru. Seluruh sumber dibaca
/// bersamaan.
///
/// ⚠ Transaksi TIDAK dibaca lewat `listAllTransactions`: arus cukup dokumen
/// bulan yang disentuh periode berjalan ± batas atribusi 7 hari (paling
/// banyak tiga), dan transaksi terbaru berhenti membaca begitu
/// [recentCount] terpenuhi — waktu tampil Beranda tidak bertambah seiring
/// panjangnya riwayat (NFR-PERF-002). Saldo diambil dari
/// `Wallet.currentBalance` yang tersimpan, bukan dihitung ulang.
final class HomeBloc extends Bloc<HomeEvent, HomeState> {
  /// Membuat [HomeBloc]. [now] bisa diganti di uji.
  HomeBloc({
    required this._walletRepository,
    required this._transactionRepository,
    required this._budgetOverviewSource,
    required this._freelanceOverviewSource,
    required LedgerChanges ledgerChanges,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(HomeState.initial()) {
    on<HomeStarted>(_onStarted);
    on<HomeRefreshed>(_onRefreshed);
    // ADR-030 §3.4: transaksi/saldo berubah di layar lain -> muat ulang
    // tanpa kerangka.
    _ledgerSubscription = ledgerChanges.from(this).listen((_) => add(const HomeRefreshed()));
    // Awal bulan keuangan diubah, atau tanggal berganti saat aplikasi hidup.
    ActiveFinancialMonth.notifier.addListener(_refresh);
    ActiveDay.notifier.addListener(_refresh);
  }

  void _refresh() => add(const HomeRefreshed());

  /// Jumlah transaksi terbaru yang ditampilkan.
  static const recentCount = 5;

  static const _calculateCashFlow = CalculateCashFlow();

  late final StreamSubscription<void> _ledgerSubscription;
  final WalletRepository _walletRepository;
  final TransactionRepository _transactionRepository;
  final BudgetOverviewSource _budgetOverviewSource;
  final FreelanceOverviewSource _freelanceOverviewSource;
  final DateTime Function() _now;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isLoading: true, loadFailed: false));
    await _load(emit, firstLoad: true);
  }

  Future<void> _onRefreshed(HomeRefreshed event, Emitter<HomeState> emit) => _load(emit, firstLoad: false);

  Future<void> _load(Emitter<HomeState> emit, {required bool firstLoad}) async {
    final now = _now();
    final period = ActiveFinancialMonth.periodOf(now);
    final (wallets, monthTransactions, recent, budget, freelance) = await (
      _walletRepository.listWallets(),
      _periodTransactions(period),
      _transactionRepository.listRecentTransactions(recentCount),
      _budgetOverviewSource.activeBudgetOverview(),
      _freelanceOverviewSource.freelanceOverview(),
    ).wait;
    switch ((wallets, monthTransactions, recent, budget, freelance)) {
      case (
        Right(value: final wallets),
        Right(value: final monthTransactions),
        Right(value: final recent),
        Right(value: final budget),
        Right(value: final freelance),
      ):
        emit(
          HomeState(
            wallets: wallets,
            recentTransactions: recent,
            hasTransactions: recent.isNotEmpty,
            period: period,
            cashFlow: _calculateCashFlow.inPeriod(monthTransactions, from: period.start, until: period.end),
            budget: budget.activeCount == 0 ? null : budget,
            freelance: freelance,
            isLoading: false,
          ),
        );
      default:
        final failure = <Either<Failure, Object?>>[
          wallets,
          monthTransactions,
          recent,
          budget,
          freelance,
        ].map((result) => result.fold((failure) => failure, (_) => null)).nonNulls.first;
        // Pemuatan pertama yang gagal menampilkan layar "coba lagi"; gagal
        // menyegarkan mempertahankan angka lama dan cukup memberi tahu.
        emit(
          firstLoad
              ? state.copyWith(isLoading: false, loadFailed: true, effect: _effectError(failure))
              : state.copyWith(effect: _effectError(failure)),
        );
    }
  }

  /// Transaksi dokumen bulan yang disentuh [period] ditambah
  /// [periodAttributionDays] hari di kedua sisi (P-4).
  Future<Either<Failure, List<Transaction>>> _periodTransactions(FinancialPeriod period) async {
    final from = DateTime(period.start.year, period.start.month, period.start.day - periodAttributionDays);
    final until = DateTime(period.end.year, period.end.month, period.end.day + periodAttributionDays);
    final all = <Transaction>[];
    for (var m = DateTime(from.year, from.month); m.isBefore(until); m = DateTime(m.year, m.month + 1)) {
      switch (await _transactionRepository.listTransactionsInMonth(m)) {
        case Left(:final value):
          return left(value);
        case Right(:final value):
          all.addAll(value);
      }
    }
    return right(all);
  }

  @override
  Future<void> close() async {
    ActiveFinancialMonth.notifier.removeListener(_refresh);
    ActiveDay.notifier.removeListener(_refresh);
    await _ledgerSubscription.cancel();
    return super.close();
  }
}
