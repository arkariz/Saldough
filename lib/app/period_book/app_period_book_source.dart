import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/analysis/domain/period_comparison.dart';
import 'package:saldough/features/analysis/domain/period_summary.dart';
import 'package:saldough/features/analysis/domain/summarize_period.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';
import 'package:saldough/features/period_book/domain/repositories/period_book_source.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// [PeriodBookSource] yang **memanggil** model baca yang sudah ada dan tidak
/// punya aturan hitung sendiri (BP-4, ADR-045 §3.2):
///
/// - halaman 1: `CalculateCashFlow.inPeriod` (Arus Beranda);
/// - halaman 2 dan 3: `summarizePeriod`, `comparisonPeriods`, `comparePeriod`,
///   dan `highlightsOf` (Analisis), dengan pembanding dan batas sorotan yang sama;
/// - halaman 4: `occurrenceStatusesOf` (rutin) dan `PlanBudgetSource` (kilas
///   balik rencana, sama dengan Rencana › Bulan ini).
///
/// Karena sumbernya sama, angka buku cocok dengan Beranda dan Analisis (B-3,
/// B-15); `app_period_book_source_test.dart` menjaganya.
final class AppPeriodBookSource implements PeriodBookSource {
  /// Membuat [AppPeriodBookSource]. [highlightMinSen] = batas sorotan sesuai
  /// mata uang aktif (`highlightMinSenOf(ActiveCurrency.value)`).
  const AppPeriodBookSource({
    required this._transactions,
    required this._categories,
    required this._schedule,
    required this._rules,
    required this._budgets,
    required this._highlightMinSen,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final TransactionRepository _transactions;
  final CategoryRepository _categories;
  final FinancialMonthPreferenceRepository _schedule;
  final RecurringRuleRepository _rules;
  final PlanBudgetSource _budgets;
  final int Function() _highlightMinSen;
  final DateTime Function() _now;

  @override
  Future<Either<Failure, PeriodBookContent>> contentFor(ClosedPeriod closed) async {
    final all = await _transactions.listAllTransactions();
    final months = await _transactions.listAvailableMonths();
    final categories = await _categories.listCategories();
    final schedule = await _schedule.load();
    final rules = (await _rules.listRules()).getOrElse((_) => const []);
    final budgets = await _budgets.budgetsStartingIn(closed.period.start, closed.period.end);

    // Gagal membaca data inti = gagal; rutin dan anggaran adalah data sekunder.
    for (final failure in [all.swap().toNullable(), months.swap().toNullable(), categories.swap().toNullable(), schedule.swap().toNullable()]) {
      if (failure != null) return Left(failure);
    }
    return Right(
      _build(
        closed: closed,
        transactions: all.getOrElse((_) => const []),
        months: months.getOrElse((_) => const []),
        categories: categories.getOrElse((_) => const []),
        schedule: schedule.getOrElse((_) => FinancialMonthSchedule.initial),
        rules: rules,
        budgets: budgets.getOrElse((_) => const []),
      ),
    );
  }

  PeriodBookContent _build({
    required ClosedPeriod closed,
    required List<Transaction> transactions,
    required List<DateTime> months,
    required List<Category> categories,
    required FinancialMonthSchedule schedule,
    required List<RecurringRule> rules,
    required List<PlanBudget> budgets,
  }) {
    final period = closed.period;
    final byId = {for (final c in categories) c.id: c};
    Category? categoryOf(String id) => byId[id];

    final flow = const CalculateCashFlow().inPeriod(transactions, from: period.start, until: period.end);
    final expense = summarizePeriod(
      transactions,
      from: period.start,
      until: period.end,
      kind: CategoryKind.expense,
      categoryOf: categoryOf,
    );
    final income = summarizePeriod(
      transactions,
      from: period.start,
      until: period.end,
      kind: CategoryKind.income,
      categoryOf: categoryOf,
    );
    final untagged = (expense.groupOf('uncategorized')?.count ?? 0) + (income.groupOf('uncategorized')?.count ?? 0);

    return PeriodBookContent(
      period: closed,
      flow: BookFlow(income: flow.income, expense: flow.expense),
      uncategorizedCount: untagged,
      spending: expense.isEmpty
          ? null
          : BookSpending(total: expense.total, count: expense.count, rows: [for (final g in expense.groups) _row(g)]),
      compare: _compare(period, transactions, months, schedule, expense, categoryOf),
      plan: _plan(period, transactions, rules, budgets),
    );
  }

  BookCompare? _compare(
    FinancialPeriod period,
    List<Transaction> transactions,
    List<DateTime> months,
    FinancialMonthSchedule schedule,
    PeriodSummary expense,
    Category? Function(String id) categoryOf,
  ) {
    if (months.isEmpty) return null;
    // Sama dengan `AnalysisBloc`: periode pencatatan pertama dari bulan tertua.
    final first = months.reduce((a, b) => a.isBefore(b) ? a : b);
    final earliest = schedule.periodOf(DateTime(first.year, first.month));
    final periods = comparisonPeriods(period: period, schedule: schedule, earliestStart: earliest.start);
    final comparison = comparePeriod(
      transactions: transactions,
      period: period,
      periods: periods,
      kind: CategoryKind.expense,
      categoryOf: categoryOf,
      minSen: _highlightMinSen(),
    );
    if (comparison == null) return null;
    return BookCompare(
      months: comparison.months,
      highlights: [
        for (final h in comparison.highlightsOf(expense))
          BookHighlight(
            kind: h.group.kind == AnalysisGroupKind.freelance ? BookRowKind.freelance : BookRowKind.category,
            amount: h.group.amount,
            average: (h.comparison.baselineSum * 2 + h.comparison.months) ~/ (2 * h.comparison.months),
            percent: _percentOf(h.comparison),
            isHigher: h.comparison.isHigher,
            categoryId: h.group.category?.id,
            categoryName: h.group.category?.name,
          ),
      ],
    );
  }

  /// Selisih persen terhadap rata-rata, dibulatkan setengah ke atas, dengan
  /// bilangan bulat murni (rata-rata tidak dibulatkan dulu; sama dengan aturan
  /// `Comparison`, B-6). Pembanding sorotan selalu punya dasar > 0.
  static int _percentOf(Comparison c) {
    final scaled = (c.amount * c.months - c.baselineSum).abs();
    return (scaled * 200 + c.baselineSum) ~/ (2 * c.baselineSum);
  }

  BookPlan? _plan(
    FinancialPeriod period,
    List<Transaction> transactions,
    List<RecurringRule> rules,
    List<PlanBudget> budgets,
  ) {
    var recorded = 0;
    var skipped = 0;
    for (final rule in rules) {
      for (final o in occurrenceStatusesOf(
        rule,
        from: period.start,
        until: period.end,
        today: _now(),
        transactions: transactions,
      )) {
        if (o.status == OccurrenceStatus.recorded) recorded++;
        if (o.status == OccurrenceStatus.skipped) skipped++;
      }
    }
    final lines = [for (final b in budgets) ...b.lines];
    final plan = BookPlan(
      recorded: recorded,
      skipped: skipped,
      planned: lines.isEmpty ? null : lines.fold<int>(0, (sum, l) => sum + l.planned),
      spent: lines.isEmpty ? null : lines.fold<int>(0, (sum, l) => sum + l.spent),
    );
    return plan.hasRoutine || plan.hasBudget ? plan : null;
  }

  BookSpendRow _row(AnalysisGroup g) => BookSpendRow(
    kind: switch (g.kind) {
      AnalysisGroupKind.category => BookRowKind.category,
      AnalysisGroupKind.freelance => BookRowKind.freelance,
      AnalysisGroupKind.uncategorized => BookRowKind.uncategorized,
      AnalysisGroupKind.others => BookRowKind.others,
    },
    amount: g.amount,
    count: g.count,
    percent: g.share.percent,
    belowOne: g.share.belowOne,
    categoryId: g.category?.id,
    categoryName: g.category?.name,
    builtInKey: g.category?.builtInKey,
  );
}
