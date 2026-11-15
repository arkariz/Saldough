import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/app/period_book/app_period_book_source.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/analysis/domain/period_comparison.dart';
import 'package:saldough/features/analysis/domain/summarize_period.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

final class _Txs implements TransactionRepository {
  _Txs(this.all);
  final List<Transaction> all;

  @override
  Future<Either<Failure, List<Transaction>>> listAllTransactions() async => Right(all);

  @override
  Future<Either<Failure, List<DateTime>>> listAvailableMonths() async =>
      Right({for (final t in all) DateTime(t.date.year, t.date.month)}.toList());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Cats implements CategoryRepository {
  _Cats(this.all);
  final List<Category> all;

  @override
  Future<Either<Failure, List<Category>>> listCategories() async => Right(all);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Schedule implements FinancialMonthPreferenceRepository {
  _Schedule(this.schedule);
  final FinancialMonthSchedule schedule;

  @override
  Future<Either<Failure, FinancialMonthSchedule>> load() async => Right(schedule);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Rules implements RecurringRuleRepository {
  _Rules(this.rules);
  final List<RecurringRule> rules;

  @override
  Future<Either<Failure, List<RecurringRule>>> listRules() async => Right(rules);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Budgets implements PlanBudgetSource {
  _Budgets(this.budgets);
  final List<PlanBudget> budgets;

  @override
  Future<Either<Failure, List<PlanBudget>>> budgetsStartingIn(DateTime from, DateTime until) async => Right(budgets);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const kMinSen = 5000000; // Rp50.000 dalam sen
final DateTime today = DateTime(2026, 11, 14);

Category cat(String id, CategoryKind kind) => Category(id: id, kind: kind, name: 'Kategori $id', builtInKey: id);

ExpenseTransaction exp(String id, DateTime d, int amount, {String? cat = 'makan', RecurrenceLink? recurrence}) =>
    ExpenseTransaction(id: id, date: d, amount: amount, note: '', walletId: 'w', categoryId: cat, recurrence: recurrence);

IncomeTransaction inc(String id, DateTime d, int amount, {String? cat = 'gaji', String? freelance}) =>
    IncomeTransaction(id: id, date: d, amount: amount, note: '', walletId: 'w', categoryId: cat, freelancePaymentId: freelance);

RecurringRule rule(String id, {Set<DateTime> skipped = const {}}) => RecurringRule(
  id: id,
  kind: RecurringKind.expense,
  amount: 100000,
  walletId: 'w',
  schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 10, 10)),
  skippedDates: skipped,
);

/// Data uji: Oktober lengkap (semua jenis baris) dan tiga bulan pembanding.
List<Transaction> data() => [
  // Pembanding: makan rata-rata Rp1.000.000 per bulan.
  for (final m in [7, 8, 9]) exp('prev$m', DateTime(2026, m, 5), 100000000),
  // Oktober.
  inc('gaji', DateTime(2026, 10), 850000000),
  inc('fl', DateTime(2026, 10, 5), 200000000, cat: null, freelance: 'p1'),
  inc('lain', DateTime(2026, 10, 6), 5000000, cat: null),
  exp('m1', DateTime(2026, 10, 2), 100000000),
  exp('m2', DateTime(2026, 10, 3), 80000000),
  exp('t1', DateTime(2026, 10, 4), 40000000, cat: 'transport'),
  exp('t2', DateTime(2026, 10, 5), 25000000, cat: 'transport'),
  exp('h', DateTime(2026, 10, 7), 30000000, cat: 'hiburan'),
  exp('k', DateTime(2026, 10, 8), 20000000, cat: 'kos'),
  exp('i', DateTime(2026, 10, 9), 10000000, cat: 'internet'),
  exp('l', DateTime(2026, 10, 9), 5000000, cat: 'listrik'),
  exp('u', DateTime(2026, 10, 12), 7000000, cat: null),
  // Rutin: r1 tercatat tertaut, r2 dilewati.
  exp('rr', DateTime(2026, 10, 10), 10000000, cat: 'kos', recurrence: RecurrenceLink(ruleId: 'r1', occurrenceDate: DateTime(2026, 10, 10))),
  TransferTransaction(id: 'tf', date: DateTime(2026, 10, 10), amount: 999999999, note: '', fromWalletId: 'w', toWalletId: 'v'),
];

final List<Category> categories = [
  cat('gaji', CategoryKind.income),
  for (final id in ['makan', 'transport', 'hiburan', 'kos', 'internet', 'listrik']) cat(id, CategoryKind.expense),
];

AppPeriodBookSource source({
  List<Transaction>? txs,
  FinancialMonthSchedule? schedule,
  List<PlanBudget> budgets = const [],
  List<RecurringRule>? rules,
}) => AppPeriodBookSource(
  transactions: _Txs(txs ?? data()),
  categories: _Cats(categories),
  schedule: _Schedule(schedule ?? FinancialMonthSchedule.initial),
  rules: _Rules(rules ?? [rule('r1'), rule('r2', skipped: {DateTime(2026, 10, 10)})]),
  budgets: _Budgets(budgets),
  highlightMinSen: () => kMinSen,
  now: () => today,
);

ClosedPeriod october(FinancialMonthSchedule schedule, List<Transaction> txs) =>
    closedOf(schedule, txs, DateTime(2026, 10, 15));

ClosedPeriod closedOf(FinancialMonthSchedule schedule, List<Transaction> txs, DateTime inPeriod) {
  final period = financialPeriodOf(inPeriod, schedule);
  return ClosedPeriod(period: period, transactionCount: txs.length);
}

PeriodBookContent contentOf(Either<Failure, PeriodBookContent> r) => r.getOrElse((f) => throw StateError('$f'));

void main() {
  final schedule = FinancialMonthSchedule.initial;

  test('halaman 1: sama persis dengan Arus Beranda; transfer tidak dihitung', () async {
    final txs = data();
    final content = contentOf(await source().contentFor(october(schedule, txs)));
    final home = const CalculateCashFlow().inPeriod(txs, from: DateTime(2026, 10), until: DateTime(2026, 11));
    expect(content.flow.income, home.income);
    expect(content.flow.expense, home.expense);
    expect(content.flow.net, home.net);
    // Dihitung tangan: 8.500.000 + 2.000.000 + 50.000 dan 1.000.000 + 800.000 + ... (sen).
    expect(content.flow.income, 850000000 + 200000000 + 5000000);
    expect(content.flow.expense, 100000000 + 80000000 + 40000000 + 25000000 + 30000000 + 20000000 + 10000000 + 5000000 + 7000000 + 10000000);
  });

  test('halaman 2: total sama dengan Analisis dan Arus; baris lima teratas + Lainnya + Tanpa kategori', () async {
    final txs = data();
    final content = contentOf(await source().contentFor(october(schedule, txs)));
    final analysis = summarizePeriod(
      txs,
      from: DateTime(2026, 10),
      until: DateTime(2026, 11),
      kind: CategoryKind.expense,
      categoryOf: (id) => categories.where((c) => c.id == id).firstOrNull,
    );
    final spending = content.spending!;
    expect(spending.total, analysis.total);
    expect(spending.total, content.flow.expense, reason: 'B-3: pengeluaran halaman 2 = pengeluaran halaman 1');
    expect(spending.rows.fold<int>(0, (s, r) => s + r.amount), spending.total, reason: 'baris menjumlah total');
    expect(
      spending.rows.map((r) => r.kind.name),
      analysis.groups.map((g) => g.kind.name),
      reason: 'jenis dan urutan baris = Analisis (lima teratas, Lainnya bila perlu, Tanpa kategori)',
    );
    expect(spending.rows.first.categoryId, 'makan');
    expect(spending.rows.first.amount, 180000000);
    // Persen = aturan Analisis (setengah ke atas, tidak dipaksa 100).
    for (final (i, g) in analysis.groups.indexed) {
      expect(spending.rows[i].percent, g.share.percent);
      expect(spending.rows[i].belowOne, g.share.belowOne);
    }
  });

  test('pemasukan freelance tanpa kategori tidak masuk pengeluaran; catatan netral menghitung tanpa kategori', () async {
    final content = contentOf(await source().contentFor(october(schedule, data())));
    expect(content.spending!.rows.any((r) => r.kind == BookRowKind.freelance), isFalse);
    // 1 pengeluaran tanpa kategori + 1 pemasukan tanpa kategori (freelance tidak dihitung).
    expect(content.uncategorizedCount, 2);
  });

  test('halaman 3: sorotan sama dengan perbandingan Analisis; tanda dan persen netral', () async {
    final txs = data();
    final content = contentOf(await source().contentFor(october(schedule, txs)));
    final compare = content.compare!;
    expect(compare.months, 3);
    expect(compare.highlights, isNotEmpty);
    expect(compare.highlights.length, lessThanOrEqualTo(3));
    final makan = compare.highlights.firstWhere((h) => h.categoryId == 'makan');
    expect(makan.isHigher, isTrue);
    expect(makan.average, 100000000);
    expect(makan.percent, 80, reason: '1.800.000 terhadap rata-rata 1.000.000');

    Category? categoryOf(String id) => categories.where((c) => c.id == id).firstOrNull;
    final periods = comparisonPeriods(
      period: financialPeriodOf(DateTime(2026, 10, 15), schedule),
      schedule: schedule,
      earliestStart: DateTime(2026, 7),
    );
    final direct = comparePeriod(
      transactions: txs,
      period: financialPeriodOf(DateTime(2026, 10, 15), schedule),
      periods: periods,
      kind: CategoryKind.expense,
      categoryOf: categoryOf,
    )!;
    final analysis = summarizePeriod(
      txs,
      from: DateTime(2026, 10),
      until: DateTime(2026, 11),
      kind: CategoryKind.expense,
      categoryOf: categoryOf,
    );
    expect(compare.highlights.map((h) => h.categoryId), direct.highlightsOf(analysis).map((h) => h.group.category?.id));
  });

  test('halaman 3 hilang bila periodenya peralihan atau belum ada pembanding', () async {
    final first = [for (final t in data().where((t) => t.date.month == 10)) t];
    final content = contentOf(await source(txs: first).contentFor(october(schedule, first)));
    expect(content.compare, isNull, reason: 'tidak ada bulan pembanding');
  });

  test('halaman 4: rutin tercatat/dilewati dan rencana vs kenyataan; hilang bila tidak ada keduanya', () async {
    final withPlan = contentOf(
      await source(
        budgets: [
          PlanBudget(
            walletId: 'w',
            periodEnd: DateTime(2026, 11),
            lines: const [(itemId: 'a', key: null, planned: 500000000, spent: 184000000)],
          ),
        ],
      ).contentFor(october(schedule, data())),
    );
    expect(withPlan.plan!.recorded, 1);
    expect(withPlan.plan!.skipped, 1);
    expect(withPlan.plan!.open, 0, reason: 'semua rutin beres');
    expect(withPlan.plan!.planned, 500000000);
    expect(withPlan.plan!.spent, 184000000);

    final none = contentOf(await source(rules: const []).contentFor(october(schedule, data())));
    expect(none.plan, isNull);
  });

  test('dihitung langsung: dua kali baca memberi hasil sama (B-15), dan memakai periode apa adanya', () async {
    final a = contentOf(await source().contentFor(october(schedule, data())));
    final b = contentOf(await source().contentFor(october(schedule, data())));
    expect(a, b);
  });

  test('jadwal tanggal 25: angka mengikuti keanggotaan periode, sama dengan Arus', () async {
    final schedule25 = FinancialMonthSchedule.single(const FinancialMonthStart.day(25));
    final txs = [
      exp('a', DateTime(2026, 9, 26), 100000000),
      exp('b', DateTime(2026, 10, 24), 50000000),
      exp('c', DateTime(2026, 10, 25), 70000000), // periode berikutnya
      inc('g', DateTime(2026, 9, 25), 800000000),
    ];
    final closed = closedOf(schedule25, txs, DateTime(2026, 10));
    final content = contentOf(await source(txs: txs, schedule: schedule25, rules: const []).contentFor(closed));
    final home = const CalculateCashFlow().inPeriod(txs, from: DateTime(2026, 9, 25), until: DateTime(2026, 10, 25));
    expect((content.flow.income, content.flow.expense), (home.income, home.expense));
    expect(content.flow.expense, 150000000);
    expect(content.spending!.total, content.flow.expense);
  });
}
