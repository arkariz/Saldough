import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/budget/data/adapters/plan_budget_source_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_template_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_schedule.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/domain/usecases/birth_recurring_budgets.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Periode virtual anggaran rutin untuk bulan depan (ADR-036 §3.5, T-16.6).
void main() {
  test('periode yang belum lahir jadi virtual (rencana penuh); yang sudah lahir tidak dobel', () async {
    final storage = InMemoryKeyValueStorage();
    final budgets = BudgetRepositoryImpl(storage: storage);
    final templates = BudgetTemplateRepositoryImpl(storage: storage);
    final template = BudgetTemplate(
      id: 't1',
      name: 'Bulanan',
      items: const [BudgetItem(id: 'kos', name: 'Kos', enteredAmount: 200000000)],
      schedule: BudgetSchedule(walletId: 'bca', period: BudgetPeriod.monthly, anchorDate: DateTime(2026, 10)),
    );
    await templates.saveTemplate(template);
    await BirthRecurringBudgets(budgets: budgets, templates: templates)(DateTime(2026, 10, 2));
    final source = PlanBudgetSourceImpl(
      budgetRepository: budgets,
      transactionRepository: TransactionRepositoryImpl(storage: storage),
      templateRepository: templates,
    );

    final october = (await source.scheduledBudgetsStartingIn(DateTime(2026, 10), DateTime(2026, 11))).getOrElse(
      (_) => const [],
    );
    expect(october, isEmpty);
    final november = (await source.scheduledBudgetsStartingIn(DateTime(2026, 11), DateTime(2026, 12))).getOrElse(
      (_) => const [],
    );
    expect(november.single.periodEnd, DateTime(2026, 12));
    expect(november.single.lines.single.planned, 200000000);
    expect(november.single.lines.single.spent, 0);
    expect(november.single.lines.single.key, 'kos');
  });
}
