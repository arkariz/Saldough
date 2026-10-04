import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/features/plan/presentation/bloc/plan_month_state.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Event [PlanMonthBloc].
sealed class PlanMonthEvent {
  /// Membuat [PlanMonthEvent].
  const PlanMonthEvent();
}

/// Memuat (dengan kerangka bila [showSkeleton]).
final class PlanMonthLoaded extends PlanMonthEvent {
  /// Membuat [PlanMonthLoaded].
  const PlanMonthLoaded({this.showSkeleton = true});

  /// Tampilkan kerangka.
  final bool showSkeleton;
}

/// Dompet kartu saldo dipilih; `null` = semua.
final class PlanMonthWalletChanged extends PlanMonthEvent {
  /// Membuat [PlanMonthWalletChanged].
  const PlanMonthWalletChanged(this.walletId);

  /// Dompetnya.
  final String? walletId;
}

/// Sakelar "Hitung jajan harian".
final class PlanMonthUnplannedToggled extends PlanMonthEvent {
  /// Membuat [PlanMonthUnplannedToggled].
  const PlanMonthUnplannedToggled({required this.enabled});

  /// Nyala atau mati.
  final bool enabled;
}

/// Bloc segmen **Bulan ini** dan baris perkiraan di Beranda (T-15.13).
/// Hanya membaca; tidak ada yang ditulis dari sini.
final class PlanMonthBloc extends Bloc<PlanMonthEvent, PlanMonthState> {
  /// Membuat [PlanMonthBloc]. [now] bisa diganti di uji.
  PlanMonthBloc({
    required this._wallets,
    required this._transactions,
    required this._rules,
    required this._budgets,
    required this._freelance,
    required LedgerChanges ledgerChanges,
    required RecurringChanges recurringChanges,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(PlanMonthState(today: DateTime.now(), range: financialMonthOf(DateTime.now(), 1))) {
    on<PlanMonthLoaded>(_onLoaded);
    on<PlanMonthWalletChanged>((event, emit) => emit(state.copyWith(walletId: () => event.walletId)));
    on<PlanMonthUnplannedToggled>((event, emit) => emit(state.copyWith(includeUnplanned: event.enabled)));
    void refresh() => add(const PlanMonthLoaded(showSkeleton: false));
    _subscriptions = [
      ledgerChanges.changes.listen((_) => refresh()),
      recurringChanges.changes.listen((_) => refresh()),
    ];
    ActiveFinancialMonth.notifier.addListener(refresh);
    _removeMonthListener = () => ActiveFinancialMonth.notifier.removeListener(refresh);
  }

  final WalletRepository _wallets;
  final TransactionRepository _transactions;
  final RecurringRuleRepository _rules;
  final PlanBudgetSource _budgets;
  final PlanFreelanceSource _freelance;
  final DateTime Function() _now;
  late final List<StreamSubscription<void>> _subscriptions;
  late final void Function() _removeMonthListener;

  Future<void> _onLoaded(PlanMonthLoaded event, Emitter<PlanMonthState> emit) async {
    if (event.showSkeleton) emit(state.copyWith(isLoading: true));
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final range = financialMonthOf(today, ActiveFinancialMonth.startDay);
    Failure? failure;
    T? read<T>(Either<Failure, T> result) => result.fold((f) {
      failure ??= f;
      return null;
    }, (value) => value);

    final wallets = read(await _wallets.listWallets());
    final rules = read(await _rules.listRules());
    final budgets = read(await _budgets.budgetsStartingIn(range.start, range.end));
    // Freelance adalah data sekunder: gagal dibaca berarti tanpa "belum pasti".
    final uncertain = (await _freelance.unpaid()).getOrElse((_) => const []);
    final months = read(await _transactions.listAvailableMonths()) ?? const <DateTime>[];
    final transactions = <Transaction>[];
    // Tiga bulan keuangan lalu (rata-rata di luar rencana) sampai akhir bulan ini.
    final from = DateTime(range.start.year, range.start.month - 3, range.start.day);
    for (var m = DateTime(from.year, from.month); m.isBefore(range.end); m = DateTime(m.year, m.month + 1)) {
      transactions.addAll(read(await _transactions.listTransactionsInMonth(m)) ?? const []);
    }
    if (failure != null) {
      emit(
        state.copyWith(
          isLoading: false,
          loadFailed: true,
          effect: ShowSnackBarEffect(message: failure!.userMessage ?? t.common.genericErrorMessage, severity: .error),
        ),
      );
      return;
    }
    final earliestMonth = months.isEmpty ? null : months.reduce((a, b) => a.isBefore(b) ? a : b);
    final earliestLoaded = transactions.isEmpty
        ? null
        : transactions.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final historyStart = earliestMonth == null
        ? null
        : (earliestLoaded != null &&
                  earliestLoaded.year == earliestMonth.year &&
                  earliestLoaded.month == earliestMonth.month
              ? earliestLoaded
              : earliestMonth);
    emit(
      state.copyWith(
        today: today,
        range: range,
        isLoading: false,
        loadFailed: false,
        wallets: [
          for (final w in wallets!)
            if (w.isActive) w,
        ],
        rules: rules,
        budgets: budgets,
        uncertain: uncertain,
        transactions: transactions,
        historyStart: historyStart,
      ),
    );
  }

  @override
  Future<void> close() async {
    _removeMonthListener();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
