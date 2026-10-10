import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/features/plan/presentation/bloc/plan_month_state.dart';
import 'package:saldough/features/record/presentation/widgets/record_budget_item_field.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// T-18.1 (ADR-038 §7, FINANCIAL_PERIOD P-4): uji karakterisasi gajian maju
/// dan tautan pos **sebelum** Fase 18 mengubah apa pun. Uji ini memotret
/// perilaku sekarang, bukan perilaku yang diinginkan; temuannya ada di entri
/// T-18.1 TASK_LIST. Bulan keuangan mulai tanggal 25, hari ini 26 Okt 2026.
void main() {
  final schedule = FinancialMonthSchedule.single(const FinancialMonthStart.day(25));
  final today = DateTime(2026, 10, 26);
  final current = financialPeriodOf(today, schedule);
  final previous = financialPeriodOf(DateTime(2026, 10, 23), schedule);
  final occurrence = DateTime(2026, 10, 25);

  RecurringRule rule(String id, RecurringKind kind, int amount, {String? budgetItemKey}) => RecurringRule(
    id: id,
    kind: kind,
    amount: amount,
    walletId: 'bca',
    note: id,
    schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 9, 25)),
    budgetItemKey: budgetItemKey,
  );

  final gajiRule = rule('gaji', RecurringKind.income, 1200000000);
  final cicilanRule = rule('cicilan', RecurringKind.expense, 291400000, budgetItemKey: 'k-cicilan');
  final rules = [gajiRule, cicilanRule];

  // Anggaran rutin Bulanan periode 25 Okt – 24 Nov dengan pos Cicilan.
  final budget = Budget(
    id: 'bulanan-okt',
    name: 'Bulanan',
    walletId: 'bca',
    period: BudgetPeriod.monthly,
    startDate: DateTime(2026, 10, 25),
    templateId: 'tpl-bulanan',
    items: const [
      BudgetItem(id: 'cicilan-okt', name: 'Cicilan', enteredAmount: 291400000, templateItemId: 'k-cicilan'),
    ],
  );
  final options = [
    BudgetItemOption(
      budgetId: budget.id,
      budgetName: budget.name,
      itemId: 'cicilan-okt',
      itemName: 'Cicilan',
      walletId: 'bca',
      startDate: budget.startDate,
      endDate: budget.endDate,
      templateItemId: 'k-cicilan',
      plannedAmount: 291400000,
    ),
  ];

  // Contoh D: Gaji kemunculan 25 Okt (Minggu) cair Jumat 23 Okt.
  final gaji = IncomeTransaction(
    id: 'gaji',
    date: DateTime(2026, 10, 23, 9),
    amount: 1200000000,
    note: 'Gaji',
    walletId: 'bca',
    recurrence: RecurrenceLink(ruleId: 'gaji', occurrenceDate: occurrence),
  );
  // Cicilan tertaut pos dicatat 24 Okt untuk kemunculan 25 Okt; posnya
  // dipilih menurut tanggal kemunculan (ADR-036 §3.4).
  final cicilan = ExpenseTransaction(
    id: 'cicilan',
    date: DateTime(2026, 10, 24, 9),
    amount: 291400000,
    note: 'Cicilan',
    walletId: 'bca',
    budgetItemId: budgetItemForOccurrence(cicilanRule, occurrence, options),
    recurrence: RecurrenceLink(ruleId: 'cicilan', occurrenceDate: occurrence),
  );

  // Terpakai pos dihitung seperti PlanBudgetSourceImpl.
  final progress = const CalculateBudgetProgress()(budget, [gaji, cicilan], now: today);
  final state = PlanMonthState(
    today: today,
    range: current,
    schedule: schedule,
    isLoading: false,
    rules: rules,
    transactions: [gaji, cicilan],
    budgets: [
      PlanBudget(
        walletId: 'bca',
        periodEnd: budget.endDate,
        lines: [
          for (final item in progress.items)
            (itemId: item.item.id, key: item.item.templateItemId, planned: item.item.plannedAmount, spent: item.spent),
        ],
      ),
    ],
  );

  test('rentang: periode lalu 25 Sep – 24 Okt, periode berjalan 25 Okt – 24 Nov', () {
    expect(previous, FinancialPeriod(start: DateTime(2026, 9, 25), end: DateTime(2026, 10, 25)));
    expect(current, FinancialPeriod(start: DateTime(2026, 10, 25), end: DateTime(2026, 11, 25)));
    expect(state.previousRange, previous);
  });

  group('tautan pos menurut tanggal kemunculan (ADR-036 §3.4) vs KT-1', () {
    test('pos dipilih dari periode yang memuat kemunculan 25 Okt', () {
      expect(cicilan.budgetItemId, 'cicilan-okt');
    });

    test('KT-1 di hitungan anggaran: cicilan 24 Okt tidak terhitung ke pos 25 Okt – 24 Nov', () {
      expect(countsTowardBudgetItem(budget, budget.items.single, cicilan), isFalse);
      expect(progress.items.single.spent, 0);
      expect(progress.spent, 0);
    });

    test('KT-1 di CATAT: pos 25 Okt tidak ditawarkan untuk tanggal 24 Okt dan tautannya dianggap lepas', () {
      expect(expenseBudgetChoicesFor(options, 'bca', null, cicilan.date), isEmpty);
      expect(budgetItemOutsidePeriod(options, 'cicilan-okt', cicilan.date), options.single);
    });
  });

  group('Rencana (PlanMonthState) menyaring transaksi menurut date', () {
    test('periode berjalan: Gaji dan Cicilan kemunculan 25 Okt tampak belum tercatat', () {
      final plan = state.planFor(0);
      expect(plan.plannedIncome, 1200000000);
      expect(plan.recordedIncome, 0);
      expect(plan.budgetPlanned, 291400000);
      expect(plan.budgetSpent, 0);
      expect(plan.unplannedIn, 0);
      expect(plan.unplannedOut, 0);
      expect(plan.remaining, 908600000);

      final inCurrent = [
        for (final t in state.transactions)
          if (current.contains(t.date)) t,
      ];
      final statuses = occurrenceStatusesOf(
        gajiRule,
        from: current.start,
        until: current.end,
        today: today,
        transactions: inCurrent,
      );
      expect(statuses.single.date, occurrence);
      expect(statuses.single.status, OccurrenceStatus.pending);
    });

    test('periode lalu: kedua transaksi tidak terhitung di mana pun', () {
      final plan = state.previousPlan;
      // Kemunculan 25 Sep tanpa transaksi; 23 dan 24 Okt dilewati karena
      // milik rutin yang ada tetapi kemunculannya di luar rentang.
      expect(plan.plannedIncome, 1200000000);
      expect(plan.recordedIncome, 0);
      expect(plan.plannedRecurringOut, 291400000);
      expect(plan.recordedRecurringOut, 0);
      expect(plan.unplannedIn, 0);
      expect(plan.unplannedOut, 0);
    });

    test('monthPlan sendiri mencocokkan menurut tanggal kemunculan bila transaksinya diberikan', () {
      final plan = monthPlan(
        rules,
        from: current.start,
        until: current.end,
        today: today,
        transactions: [gaji, cicilan],
        budgetLines: state.budgets.single.lines,
      );
      expect(plan.recordedIncome, 1200000000);
      expect(plan.recurringDifference, 0);
      // Cicilan tercatat dengan pos, jadi bukan "terpakai tanpa pos"; pos
      // tetap 0 karena KT-1.
      expect(plan.budgetSpent, 0);
      expect(plan.unplannedIn, 0);
      expect(plan.unplannedOut, 0);
    });
  });

  test('kartu Arus Beranda memakai bulan kalender menurut date: keduanya di Oktober', () {
    const flow = CalculateCashFlow();
    expect(flow([gaji, cicilan], month: DateTime(2026, 10)), const CashFlow(income: 1200000000, expense: 291400000));
    expect(flow([gaji, cicilan], month: DateTime(2026, 11)), const CashFlow(income: 0, expense: 0));
  });
}
