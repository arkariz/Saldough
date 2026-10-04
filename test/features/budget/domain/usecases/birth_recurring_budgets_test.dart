import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_template_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_schedule.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/domain/usecases/birth_recurring_budgets.dart';

/// Kelahiran periode anggaran rutin (ADR-036 §3.2, invarian 18, T-16.2).
void main() {
  var ids = 0;
  String newId() => 'id${ids++}';

  BudgetTemplate template({bool active = true}) => BudgetTemplate(
    id: 't1',
    name: 'Bulanan',
    items: const [
      BudgetItem(id: 'kos', name: 'Kos', enteredAmount: 190000000, templateItemId: 'kos'),
      BudgetItem(id: 'sayur', name: 'Sayur', quantity: 4, unitPrice: 2500000, templateItemId: 'sayur'),
    ],
    schedule: BudgetSchedule(
      walletId: 'bca',
      period: BudgetPeriod.monthly,
      anchorDate: DateTime(2026, 10),
      isActive: active,
    ),
  );

  test('periode berjalan lahir dengan pos id baru dan kunci pos template', () {
    final born = dueBirths([template()], const [], today: DateTime(2026, 11, 3, 8), newId: newId);
    final budget = born.single;
    expect(budget.startDate, DateTime(2026, 11));
    expect(budget.walletId, 'bca');
    expect(budget.templateId, 't1');
    expect(budget.name, 'Bulanan');
    expect(budget.plannedAmount, 200000000);
    expect(budget.items.map((i) => i.templateItemId), ['kos', 'sayur']);
    expect(budget.items.map((i) => i.id), isNot(contains('kos')));
  });

  test('idempoten: periode yang sudah ada (arsip pun) tidak lahir lagi', () {
    final existing = Budget(
      id: 'okt',
      name: 'Bulanan',
      walletId: 'bca',
      period: BudgetPeriod.monthly,
      startDate: DateTime(2026, 10),
      templateId: 't1',
      isArchived: true,
    );
    expect(dueBirths([template()], [existing], today: DateTime(2026, 10, 20), newId: newId), isEmpty);
  });

  test('periode terlewat tidak diisi; sebelum patokan dan jadwal mati tidak lahir', () {
    final born = dueBirths([template()], const [], today: DateTime(2027, 1, 15), newId: newId);
    expect(born.map((b) => b.startDate), [DateTime(2027)]);
    expect(dueBirths([template()], const [], today: DateTime(2026, 9, 30), newId: newId), isEmpty);
    expect(dueBirths([template(active: false)], const [], today: DateTime(2026, 11, 3), newId: newId), isEmpty);
  });

  test('use case menyimpan sekali walau dipanggil dua kali', () async {
    final storage = InMemoryKeyValueStorage();
    final budgets = BudgetRepositoryImpl(storage: storage);
    final templates = BudgetTemplateRepositoryImpl(storage: storage);
    await templates.saveTemplate(template());
    final birth = BirthRecurringBudgets(budgets: budgets, templates: templates, newId: newId);

    expect((await birth(DateTime(2026, 11, 3))).getOrElse((_) => -1), 1);
    expect((await birth(DateTime(2026, 11, 4))).getOrElse((_) => -1), 0);
    expect((await budgets.listBudgets()).getOrElse((_) => const []), hasLength(1));
  });
}
