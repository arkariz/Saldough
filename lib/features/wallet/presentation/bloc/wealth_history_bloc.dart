import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/financial_month/financial_period.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/features/wallet/presentation/bloc/wealth_history_state.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:saldough/shared/wealth/wealth.dart';
import 'package:state_management/state_management.dart';

part 'wealth_history_event.dart';

/// Riwayat kekayaan (B-100, ADR-050 §3.6): Total aset di akhir tiap periode
/// keuangan dan pecahan perubahannya. Membaca seluruh buku besar sekali
/// ([TransactionRepository.listAllTransactions], satu-satunya layar selain
/// hitung ulang saldo yang butuh) lalu menghitung di memori lewat
/// [WealthHistory]. Gratis hanya dihitung untuk [freePeriods] periode
/// terakhir, jadi data periode terkunci tidak pernah sampai ke layar.
final class WealthHistoryBloc extends Bloc<WealthHistoryEvent, WealthHistoryState> {
  /// Membuat [WealthHistoryBloc]; [now] disuntikkan untuk uji.
  WealthHistoryBloc({
    required WalletRepository walletRepository,
    required TransactionRepository transactionRepository,
    required SavingsGoalRepository goalRepository,
    required this._schedule,
    required this._isPlus,
    required this._freePeriods,
    InvestmentRepository? investmentRepository,
    DateTime Function()? now,
  }) : _wallets = walletRepository,
       _transactions = transactionRepository,
       _goals = goalRepository,
       _investments = investmentRepository,
       _now = now ?? DateTime.now,
       super(WealthHistoryState.initial()) {
    on<WealthHistoryStarted>(_onStarted);
    on<WealthHistoryPointSelected>(
      (event, emit) => emit(state.copyWith(selected: event.index.clamp(0, state.points.length - 1))),
    );
  }

  final WalletRepository _wallets;
  final TransactionRepository _transactions;
  final SavingsGoalRepository _goals;
  final InvestmentRepository? _investments;
  final FinancialMonthSchedule Function() _schedule;
  final bool Function() _isPlus;
  final int Function() _freePeriods;
  final DateTime Function() _now;

  Future<void> _onStarted(WealthHistoryStarted event, Emitter<WealthHistoryState> emit) async {
    emit(state.copyWith(isLoading: true, failed: false));
    final wallets = await _wallets.listWallets();
    final transactions = await _transactions.listAllTransactions();
    final goals = await _goals.listGoals();
    final instruments = _investments == null ? const Right<Failure, List<Instrument>>([]) : await _investments.listInstruments();
    final valuations = _investments == null
        ? const Right<Failure, List<InstrumentValuation>>([])
        : await _investments.listValuations();
    if (wallets.isLeft() || transactions.isLeft() || goals.isLeft() || instruments.isLeft() || valuations.isLeft()) {
      emit(state.copyWith(isLoading: false, failed: true));
      return;
    }
    final walletList = wallets.getOrElse((_) => const []);
    final txList = transactions.getOrElse((_) => const []);
    final instrumentList = instruments.getOrElse((_) => const []);
    final history = WealthHistory(
      wallets: walletList,
      transactions: txList,
      instruments: instrumentList,
      valuations: valuations.getOrElse((_) => const []),
      goalWalletIds: {for (final g in goals.getOrElse((_) => const [])) g.walletId},
    );

    final schedule = _schedule();
    final today = _now();
    final current = schedule.periodOf(today);
    final earliest = _earliest(walletList, txList, instrumentList) ?? today;
    // Periode dari yang pertama berisi data sampai berjalan, terlama dulu.
    final unique = <FinancialPeriod>[];
    for (var p = schedule.periodOf(earliest); p.start.isBefore(current.start) && unique.length < 600; p = schedule.nextOf(p)) {
      unique.add(p);
    }
    unique.add(current);
    var visible = unique;
    var lockedOlder = false;
    if (!_isPlus()) {
      final free = _freePeriods().clamp(1, 1000);
      if (unique.length > free) {
        visible = unique.sublist(unique.length - free);
        lockedOlder = true;
      }
    }
    final points = <WealthPeriodPoint>[];
    WealthPoint? previous;
    for (final period in visible) {
      final at = period == current ? today : period.lastDay;
      final point = history.at(at);
      final change = previous == null ? null : history.change(previous.date, point.date);
      points.add((period: period, point: point, change: change));
      previous = point;
    }
    AppAnalytics.log(WealthEvents.wealthHistoryViewed(points.length, locked: lockedOlder));
    emit(
      state.copyWith(
        isLoading: false,
        points: points,
        selected: points.isEmpty ? 0 : points.length - 1,
        hasLockedOlder: lockedOlder,
      ),
    );
  }

  /// Tanggal tertua dari dompet, transaksi, dan instrumen.
  DateTime? _earliest(List<Wallet> wallets, List<Transaction> txs, List<Instrument> instruments) {
    DateTime? best;
    void consider(DateTime? d) {
      if (d != null && (best == null || d.isBefore(best!))) best = d;
    }

    for (final w in wallets) {
      consider(w.createdAt);
    }
    for (final t in txs) {
      consider(t.date);
    }
    for (final i in instruments) {
      consider(i.opening?.date);
    }
    return best;
  }
}
