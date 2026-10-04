import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_kind.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/features/budget/domain/usecases/read_transactions_in_months.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Implementasi port [PlanBudgetSource] milik `plan` (ADR-0009). Terpakai
/// dihitung [CalculateBudgetProgress] yang sama dengan layar Anggaran, dari
/// dokumen bulan periode anggaran itu saja (KT-1).
final class PlanBudgetSourceImpl implements PlanBudgetSource {
  /// Membuat [PlanBudgetSourceImpl].
  PlanBudgetSourceImpl({
    required this._budgetRepository,
    required this._transactionRepository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final BudgetRepository _budgetRepository;
  final TransactionRepository _transactionRepository;
  final DateTime Function() _now;

  @override
  Future<Either<Failure, List<PlanBudget>>> budgetsStartingIn(DateTime from, DateTime until) async {
    final List<Budget> budgets;
    switch (await _budgetRepository.listBudgets()) {
      case Left(:final value):
        return left(value);
      case Right(:final value):
        budgets = [
          for (final b in value)
            if (!b.isArchived && !b.startDate.isBefore(from) && b.startDate.isBefore(until)) b,
        ];
    }
    if (budgets.isEmpty) return right(const []);
    final transactions = await ReadTransactionsInMonths(_transactionRepository)(budgets.expand((b) => b.months));
    return transactions.map((all) {
      const calculate = CalculateBudgetProgress();
      return [
        for (final budget in budgets)
          PlanBudget(
            walletId: budget.walletId,
            periodEnd: budget.endDate,
            lines: [
              for (final item in calculate(budget, all, now: _now()).items)
                if (item.item.kind == BudgetItemKind.expense)
                  (
                    itemId: item.item.id,
                    key: item.item.templateItemId,
                    planned: item.item.plannedAmount,
                    spent: item.spent,
                  ),
            ],
          ),
      ];
    });
  }
}
