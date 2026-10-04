import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_kind.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/domain/repositories/budget_template_repository.dart';
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
    this._templateRepository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final BudgetRepository _budgetRepository;
  final TransactionRepository _transactionRepository;

  /// Template berjadwal (ADR-036); `null` = tanpa periode virtual.
  final BudgetTemplateRepository? _templateRepository;
  final DateTime Function() _now;

  @override
  Future<Either<Failure, List<PlanBudget>>> scheduledBudgetsStartingIn(DateTime from, DateTime until) async {
    final repository = _templateRepository;
    if (repository == null) return right(const []);
    final templates = await repository.listTemplates();
    if (templates case Left(:final value)) return left(value);
    final budgets = await _budgetRepository.listBudgets();
    if (budgets case Left(:final value)) return left(value);
    final born = {
      for (final b in budgets.getOrElse((_) => const []))
        if (b.templateId != null) (b.templateId, DateTime(b.startDate.year, b.startDate.month, b.startDate.day)),
    };
    return right([
      for (final template in templates.getOrElse((_) => const []))
        if (template.schedule case final schedule? when schedule.isActive)
          for (final start in schedule.startsBetween(from, until))
            if (!start.isBefore(from) && !born.contains((template.id, start)))
              PlanBudget(
                walletId: schedule.walletId,
                periodEnd: schedule.period.endFrom(start),
                lines: [
                  for (final item in template.items)
                    if (item.kind == BudgetItemKind.expense)
                      (
                        itemId: 'virtual-${template.id}-${item.id}',
                        key: item.id,
                        planned: item.plannedAmount,
                        spent: 0,
                      ),
                ],
              ),
    ]);
  }

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
