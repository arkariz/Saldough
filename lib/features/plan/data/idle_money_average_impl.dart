import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Rata-rata uang nganggur periode lengkap terakhir untuk perkiraan tujuan
/// (ADR-048 §3.6 butir 2). Tiap periode dihitung sama seperti kilas balik
/// bulan lalu di Bulan ini (`PlanMonthState.previousPlan`): [monthPlan] atas
/// rutin, anggaran yang mulai di periode itu, dan anggota periodenya.
final class IdleMoneyAverageImpl implements IdleMoneyAverage {
  /// Membuat [IdleMoneyAverageImpl].
  IdleMoneyAverageImpl({
    required this._transactions,
    required this._rules,
    required this._budgets,
    FinancialMonthSchedule Function()? schedule,
  }) : _schedule = schedule ?? (() => ActiveFinancialMonth.schedule);

  final TransactionRepository _transactions;
  final RecurringRuleRepository _rules;
  final PlanBudgetSource _budgets;
  final FinancialMonthSchedule Function() _schedule;

  @override
  Future<Either<Failure, int?>> averageBefore(DateTime today) async {
    final transactions = await _transactions.listAllTransactions();
    final rules = await _rules.listRules();
    switch ((transactions, rules)) {
      case (Left(value: final f), _) || (_, Left(value: final f)):
        return Left(f);
      case (Right(value: final txs), Right(value: final rs)):
        if (txs.isEmpty) return const Right(null);
        final first = txs.map(periodDateOf).reduce((a, b) => a.isBefore(b) ? a : b);
        final schedule = _schedule();
        var period = schedule.periodOf(today);
        var total = 0;
        var count = 0;
        for (var back = 0; back < goalEstimatePeriods; back++) {
          period = schedule.previousOf(period);
          // Periode sebelum catatan pertama bukan riwayat.
          if (!period.end.isAfter(first)) break;
          final budgets = await _budgets.budgetsStartingIn(period.start, period.end);
          if (budgets case Left(value: final f)) return Left(f);
          final plan = monthPlan(
            rs,
            from: period.start,
            until: period.end,
            today: DateTime(period.end.year, period.end.month, period.end.day - 1),
            transactions: [
              for (final tx in txs)
                if (period.contains(periodDateOf(tx))) tx,
            ],
            budgetLines: [for (final b in budgets.getOrElse((_) => const [])) ...b.lines],
          );
          total += plan.remaining;
          count++;
        }
        return Right(count == 0 ? null : total ~/ count);
    }
  }
}
