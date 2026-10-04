import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_schedule.dart';
import 'package:saldough/features/budget/domain/usecases/birth_recurring_budgets.dart';
import 'package:saldough/features/budget/domain/usecases/plan_recurring_budget_save.dart';

/// Sakelar Ulangi dan dialog lingkup (ADR-036 §3.1, §3.3, T-16.3, T-16.4).
void main() {
  var ids = 0;
  String newId() => 'k${ids++}';
  setUp(() => ids = 0);

  const kos = BudgetItem(id: 'kos-okt', name: 'Kos', enteredAmount: 190000000);
  const sayur = BudgetItem(id: 'sayur-okt', name: 'Sayur', enteredAmount: 10000000);
  final october = Budget(
    id: 'okt',
    name: 'Bulanan',
    walletId: 'bca',
    period: BudgetPeriod.monthly,
    startDate: DateTime(2026, 10),
    items: const [kos, sayur],
  );

  RecurringBudgetSave turnOn() =>
      planRecurringBudgetSave(budget: october, repeat: true, scope: BudgetEditScope.thisAndNext, newId: newId);

  test('menyalakan Ulangi: template berjadwal = anggaran ini, pos bertautan kunci', () {
    final (:budget, :template) = turnOn();
    expect(
      template!.schedule,
      BudgetSchedule(walletId: 'bca', period: BudgetPeriod.monthly, anchorDate: DateTime(2026, 10)),
    );
    expect(template.name, 'Bulanan');
    expect(template.plannedAmount, october.plannedAmount);
    expect(budget.templateId, template.id);
    expect(budget.items.map((i) => i.templateItemId), template.items.map((i) => i.id));
    // Periode berikutnya lahir dengan kunci pos yang sama.
    final november = dueBirths([template], [budget], today: DateTime(2026, 11, 2), newId: newId).single;
    expect(november.items.map((i) => i.templateItemId), budget.items.map((i) => i.templateItemId));
    expect(november.plannedAmount, october.plannedAmount);
  });

  test('hanya periode ini: template tidak berubah', () {
    final (budget: recurring, :template) = turnOn();
    final edited = recurring.copyWith(
      items: [
        ...recurring.items,
        const BudgetItem(id: 'kulkas', name: 'Kulkas', enteredAmount: 1),
      ],
    );
    final result = planRecurringBudgetSave(
      budget: edited,
      repeat: true,
      scope: BudgetEditScope.thisPeriod,
      template: template,
      newId: newId,
    );
    expect(result.template, isNull);
    expect(result.budget, edited);
  });

  test('periode ini dan berikutnya: ubah, tambah, dan hapus pos ikut ke template', () {
    final (budget: recurring, :template) = turnOn();
    final kosKey = recurring.items.first.templateItemId;
    final edited = recurring.copyWith(
      items: [
        recurring.items.first.withAmountOf(const BudgetItem(id: '-', name: '-', enteredAmount: 210000000)),
        const BudgetItem(id: 'listrik', name: 'Listrik', enteredAmount: 20000000),
      ],
    );
    final result = planRecurringBudgetSave(
      budget: edited,
      repeat: true,
      scope: BudgetEditScope.thisAndNext,
      template: template,
      newId: newId,
    );
    final next = result.template!;
    expect(next.id, template!.id);
    expect(next.items.map((i) => i.name), ['Kos', 'Listrik']);
    expect(next.items.first.id, kosKey);
    expect(next.items.first.plannedAmount, 210000000);
    expect(result.budget.items.last.templateItemId, next.items.last.id);
  });

  test('mematikan Ulangi menonaktifkan jadwal, anggaran tetap', () {
    final (budget: recurring, :template) = turnOn();
    final result = planRecurringBudgetSave(
      budget: recurring,
      repeat: false,
      scope: BudgetEditScope.thisPeriod,
      template: template,
      newId: newId,
    );
    expect(result.template!.schedule!.isActive, isFalse);
    expect(result.template!.isScheduled, isFalse);
    expect(result.budget, recurring);
  });

  test('anggaran bulanan tanggal 29 tidak bisa diulang', () {
    final late = october.copyWith(startDate: DateTime(2026, 10, 29));
    final result = planRecurringBudgetSave(
      budget: late,
      repeat: true,
      scope: BudgetEditScope.thisAndNext,
      newId: newId,
    );
    expect(result.template, isNull);
    expect(result.budget.templateId, isNull);
  });

  group('bawaan dan kebutuhan dialog lingkup', () {
    final (budget: recurring, template: _) = planRecurringBudgetSave(
      budget: october,
      repeat: true,
      scope: BudgetEditScope.thisAndNext,
      newId: () => 'x${DateTime.now().microsecondsSinceEpoch}${ids++}',
    );

    test('tambah pos → hanya periode ini; hapus pos → hanya periode ini', () {
      final added = recurring.copyWith(
        items: [
          ...recurring.items,
          const BudgetItem(id: 'b', name: 'Barber', enteredAmount: 1),
        ],
      );
      expect(defaultEditScope(recurring, added), BudgetEditScope.thisPeriod);
      expect(
        defaultEditScope(recurring, recurring.copyWith(items: [recurring.items.first])),
        BudgetEditScope.thisPeriod,
      );
    });

    test('ubah nominal pos bertemplate, nama, atau dompet → periode ini dan berikutnya', () {
      final changed = recurring.copyWith(
        items: [
          recurring.items.first.withAmountOf(const BudgetItem(id: '-', name: '-', enteredAmount: 5)),
          recurring.items.last,
        ],
      );
      expect(defaultEditScope(recurring, changed), BudgetEditScope.thisAndNext);
      expect(defaultEditScope(recurring, recurring.copyWith(name: 'Rumah')), BudgetEditScope.thisAndNext);
      expect(defaultEditScope(recurring, recurring.copyWith(walletId: 'jago')), BudgetEditScope.thisAndNext);
    });

    test('periode lalu tidak pernah ditanya (invarian 19)', () {
      final changed = recurring.copyWith(name: 'Rumah');
      expect(needsEditScope(before: recurring, after: changed, scheduled: true, today: DateTime(2026, 10, 20)), isTrue);
      expect(needsEditScope(before: recurring, after: changed, scheduled: true, today: DateTime(2026, 11)), isFalse);
      expect(
        needsEditScope(before: recurring, after: recurring, scheduled: true, today: DateTime(2026, 10, 20)),
        isFalse,
      );
      expect(
        needsEditScope(before: recurring, after: changed, scheduled: false, today: DateTime(2026, 10, 20)),
        isFalse,
      );
    });
  });
}
