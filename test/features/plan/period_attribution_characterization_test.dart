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

/// Gajian maju dan tautan pos (FINANCIAL_PERIOD P-4, ADR-038 §3.5). Semula
/// uji karakterisasi T-18.1; kini perilaku yang diharapkan untuk Rencana
/// (T-18.3) dan KT-1 (T-18.12).
/// Bulan keuangan mulai tanggal 25, hari ini 26 Okt 2026.
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

  group('KT-1 memakai tanggal periode untuk transaksi tertaut rutin (T-18.12)', () {
    test('pos dipilih dari periode yang memuat kemunculan 25 Okt', () {
      expect(cicilan.budgetItemId, 'cicilan-okt');
    });

    test('cicilan 24 Okt untuk kemunculan 25 Okt: terpakai pos periode 25 Okt = Rp2.914.000', () {
      expect(countsTowardBudgetItem(budget, budget.items.single, cicilan), isTrue);
      expect(progress.items.single.spent, 291400000);
      expect(progress.spent, 291400000);
    });

    test('pos periode 25 Sep tidak berubah; pengeluaran biasa 24 Okt tetap ke pos 25 Sep', () {
      final september = Budget(
        id: 'bulanan-sep',
        name: 'Bulanan',
        walletId: 'bca',
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 9, 25),
        templateId: 'tpl-bulanan',
        items: const [
          BudgetItem(id: 'cicilan-sep', name: 'Cicilan', enteredAmount: 291400000, templateItemId: 'k-cicilan'),
        ],
      );
      final plain = ExpenseTransaction(
        id: 'belanja',
        date: DateTime(2026, 10, 24, 19),
        amount: 5000000,
        note: 'Belanja',
        walletId: 'bca',
        budgetItemId: 'cicilan-sep',
      );
      final result = const CalculateBudgetProgress()(september, [gaji, cicilan, plain], now: today);
      expect(result.items.single.spent, 5000000);
      expect(countsTowardBudgetItem(budget, budget.items.single, plain.copyWith(budgetItemId: 'cicilan-okt')), isFalse);
    });

    test('selisih lebih dari 7 hari kembali ke date: tidak terhitung ke pos 25 Okt', () {
      final far = ExpenseTransaction(
        id: 'cicilan-jauh',
        date: DateTime(2026, 10, 17, 9),
        amount: 291400000,
        note: 'Cicilan',
        walletId: 'bca',
        budgetItemId: 'cicilan-okt',
        recurrence: RecurrenceLink(ruleId: 'cicilan', occurrenceDate: occurrence),
      );
      expect(countsTowardBudgetItem(budget, budget.items.single, far), isFalse);
    });

    test('CATAT: pos 25 Okt ditawarkan untuk isian 24 Okt yang tertaut kemunculan 25 Okt', () {
      final periodDate = periodDateFor(cicilan.date, occurrence);
      expect(expenseBudgetChoicesFor(options, 'bca', null, periodDate), options);
      expect(budgetItemOutsidePeriod(options, 'cicilan-okt', periodDate), isNull);
      // Tanpa tautan: aturan date, pos 25 Okt tidak ditawarkan.
      expect(expenseBudgetChoicesFor(options, 'bca', null, periodDateFor(cicilan.date, null)), isEmpty);
    });

    test('Rencana: terpakai pos ikut terisi', () {
      final plan = state.planFor(0);
      expect(plan.budgetSpent, 291400000);
      expect(plan.budgetOverrun, 0);
      expect(plan.remaining, 908600000);
    });

    test('awal bulan 1: rutin 1 Nov dibayar 30 Okt terhitung di pos November', () {
      final november = Budget(
        id: 'bulanan-nov',
        name: 'Bulanan',
        walletId: 'bca',
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 11),
        items: const [BudgetItem(id: 'kos-nov', name: 'Kos', enteredAmount: 190000000)],
      );
      final kos = ExpenseTransaction(
        id: 'kos',
        date: DateTime(2026, 10, 30, 9),
        amount: 190000000,
        note: 'Kos',
        walletId: 'bca',
        budgetItemId: 'kos-nov',
        recurrence: RecurrenceLink(ruleId: 'kos', occurrenceDate: DateTime(2026, 11)),
      );
      // Dokumen Oktober ikut dibaca: paling banyak satu bulan tetangga.
      expect(november.months, [DateTime(2026, 10), DateTime(2026, 11)]);
      expect(budget.months, [DateTime(2026, 10), DateTime(2026, 11)]);
      expect(const CalculateBudgetProgress()(november, [kos], now: today).items.single.spent, 190000000);
    });
  });

  group('Rencana memakai tanggal periode (T-18.3, P-4)', () {
    test('periode berjalan: Gaji dan Cicilan kemunculan 25 Okt tercatat, bukan menunggu', () {
      final plan = state.planFor(0);
      expect(plan.plannedIncome, 1200000000);
      expect(plan.recordedIncome, 1200000000);
      expect(plan.recurringDifference, 0);
      expect(plan.budgetPlanned, 291400000);
      expect(plan.budgetSpent, 291400000);
      expect(plan.unplannedIn, 0);
      expect(plan.unplannedOut, 0);
      expect(plan.remaining, 908600000);

      final members = [
        for (final t in state.transactions)
          if (current.contains(periodDateOf(t))) t,
      ];
      expect(members, [gaji, cicilan]);
      final statuses = occurrenceStatusesOf(
        gajiRule,
        from: current.start,
        until: current.end,
        today: today,
        transactions: members,
      );
      expect(statuses.single.date, occurrence);
      expect(statuses.single.status, OccurrenceStatus.recorded);
    });

    test('periode lalu 25 Sep – 24 Okt: Gaji 23 Okt dan Cicilan 24 Okt bukan anggotanya', () {
      expect(previous.contains(gaji.date), isTrue);
      expect(previous.contains(periodDateOf(gaji)), isFalse);
      final plan = state.previousPlan;
      // Kemunculan 25 Sep tanpa transaksi.
      expect(plan.plannedIncome, 1200000000);
      expect(plan.recordedIncome, 0);
      expect(plan.plannedRecurringOut, 291400000);
      expect(plan.recordedRecurringOut, 0);
      expect(plan.unplannedIn, 0);
      expect(plan.unplannedOut, 0);
    });

    test('selisih 8 hari: dihitung menurut date, kemunculan 25 Okt tetap menunggu', () {
      final early = IncomeTransaction(
        id: 'gaji-awal',
        date: DateTime(2026, 10, 17, 9),
        amount: 1200000000,
        note: 'Gaji',
        walletId: 'bca',
        recurrence: RecurrenceLink(ruleId: 'gaji', occurrenceDate: occurrence),
      );
      expect(periodDateOf(early), early.date);
      final far = state.copyWith(transactions: [early]);
      expect(far.planFor(0).recordedIncome, 0);
      expect(far.previousPlan.recordedIncome, 0);
      expect(far.previousPlan.unplannedIn, 0);
    });

    test('perkiraan harian tetap memakai date: gaji yang sudah cair tidak ditambahkan lagi', () {
      final projection = state.projectionFor(0);
      expect(projection.breakdown.income, 0);
      expect(projection.breakdown.recurringOut, 0);
    });
  });

  test('kartu Arus Beranda = pemasukan/pengeluaran monthPlan periode yang sama, tanpa transfer (T-18.4)', () {
    final jajan = ExpenseTransaction(
      id: 'jajan',
      date: DateTime(2026, 10, 26, 12),
      amount: 5700000,
      note: '',
      walletId: 'bca',
    );
    final bonus = IncomeTransaction(
      id: 'bonus',
      date: DateTime(2026, 10, 26, 13),
      amount: 50000000,
      note: '',
      walletId: 'bca',
    );
    final tabung = TransferTransaction(
      id: 'tabung',
      date: DateTime(2026, 10, 26, 14),
      amount: 100000000,
      note: '',
      fromWalletId: 'bca',
      toWalletId: 'jago',
    );
    final all = [gaji, cicilan, jajan, bonus, tabung];
    final spent = const CalculateBudgetProgress()(budget, all, now: today);
    final plan = PlanMonthState(
      today: today,
      range: current,
      schedule: schedule,
      isLoading: false,
      rules: rules,
      transactions: all,
      budgets: [
        PlanBudget(
          walletId: 'bca',
          periodEnd: budget.endDate,
          lines: [
            for (final item in spent.items)
              (itemId: item.item.id, key: item.item.templateItemId, planned: item.item.plannedAmount, spent: item.spent),
          ],
        ),
      ],
    ).planFor(0);
    final flow = const CalculateCashFlow().inPeriod(all, from: current.start, until: current.end);
    expect(flow, const CashFlow(income: 1250000000, expense: 297100000));
    expect(flow.income, plan.recordedIncome + plan.unplannedIn);
    expect(flow.expense, plan.recordedRecurringOut + plan.budgetSpent + plan.unplannedOut);
    // Kalender (cara lama) menghitung gaji 23 Okt dan cicilan 24 Okt di
    // Oktober bersama seluruh isi 25–31 Okt.
    expect(const CalculateCashFlow()(all, month: DateTime(2026, 10)), flow);
    expect(
      const CalculateCashFlow().inPeriod(all, from: previous.start, until: previous.end),
      const CashFlow(income: 0, expense: 0),
    );
  });
}
