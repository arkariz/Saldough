import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/currency/app_currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/analysis/domain/period_comparison.dart';
import 'package:saldough/features/analysis/domain/period_summary.dart';
import 'package:saldough/features/analysis/domain/summarize_period.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Pembanding dan sorotan (T-19.2, FINANCIAL_ANALYSIS B-6, B-7) dengan contoh
/// §10 dalam sen: Makan +Rp295.000 disorot, Belanja +8,8% tidak; Oktober s.d.
/// tanggal 10.
void main() {
  int rp(int rupiah) => rupiah * 100;

  Category cat(String id, String name) => Category(id: id, kind: CategoryKind.expense, name: name);
  final all = {for (final c in [cat('makan', 'Makan'), cat('belanja', 'Belanja'), cat('baru', 'Baru')]) c.id: c};
  Category? categoryOf(String id) => all[id];

  var next = 0;
  ExpenseTransaction spend(DateTime date, int rupiah, String? category) =>
      ExpenseTransaction(id: 'e${next++}', date: date, amount: rp(rupiah), note: '', walletId: 'bca', categoryId: category);

  final schedule = FinancialMonthSchedule.initial;
  final earliest = DateTime(2026, 6);

  // Juni, Juli, Agustus (§10); September; Oktober s.d. tanggal 10.
  List<Transaction> data() => [
    spend(DateTime(2026, 6, 5), 900000, 'makan'),
    spend(DateTime(2026, 7, 5), 950000, 'makan'),
    spend(DateTime(2026, 8, 5), 1000000, 'makan'),
    spend(DateTime(2026, 6, 6), 2700000, 'belanja'),
    spend(DateTime(2026, 7, 6), 2850000, 'belanja'),
    spend(DateTime(2026, 8, 6), 2910000, 'belanja'),
    spend(DateTime(2026, 9, 5), 1245000, 'makan'),
    spend(DateTime(2026, 9, 6), 3068500, 'belanja'),
  ];

  PeriodSummary summaryOf(List<Transaction> t, DateTime from, DateTime until) =>
      summarizePeriod(t, from: from, until: until, kind: CategoryKind.expense, categoryOf: categoryOf);

  PeriodComparison? compare(List<Transaction> t, DateTime date, {DateTime? today, FinancialMonthSchedule? s}) {
    final sch = s ?? schedule;
    final period = sch.periodOf(date);
    return comparePeriod(
      transactions: t,
      period: period,
      periods: comparisonPeriods(period: period, schedule: sch, earliestStart: earliest),
      kind: CategoryKind.expense,
      categoryOf: categoryOf,
      today: today,
    );
  }

  group('comparisonPeriods (B-6)', () {
    test('tiga periode tepat sebelum, terbaru dulu', () {
      final periods = comparisonPeriods(
        period: schedule.periodOf(DateTime(2026, 9, 15)),
        schedule: schedule,
        earliestStart: earliest,
      );
      expect(periods.map((p) => p.start), [DateTime(2026, 8), DateTime(2026, 7), DateTime(2026, 6)]);
    });

    test('tidak lebih awal dari bulan pertama pencatatan: Juli hanya punya Juni', () {
      final periods = comparisonPeriods(
        period: schedule.periodOf(DateTime(2026, 7, 15)),
        schedule: schedule,
        earliestStart: earliest,
      );
      expect(periods.map((p) => p.start), [DateTime(2026, 6)]);
    });

    test('bulan pertama pencatatan tidak punya pembanding', () {
      expect(
        comparisonPeriods(period: schedule.periodOf(DateTime(2026, 6, 15)), schedule: schedule, earliestStart: earliest),
        isEmpty,
      );
    });

    test('periode peralihan tidak dibandingkan, dan tidak menjadi pembanding (dibuang, bukan diganti)', () {
      final changed = schedule.changedOn(DateTime(2026, 10, 10), const FinancialMonthStart.day(25));
      final transition = changed.periodOf(DateTime(2026, 10, 10));
      expect(transition.isTransition, isTrue);
      expect(comparisonPeriods(period: transition, schedule: changed, earliestStart: earliest), isEmpty);

      // 25 Okt – 24 Nov: pembanding terdekat adalah peralihan 1–24 Okt (dibuang); sisanya Sep dan Agu.
      final period = changed.periodOf(DateTime(2026, 11));
      expect(period.start, DateTime(2026, 10, 25));
      final periods = comparisonPeriods(period: period, schedule: changed, earliestStart: earliest);
      expect(periods.map((p) => p.start), [DateTime(2026, 9), DateTime(2026, 8)]);
      expect(periods.any((p) => p.isTransition), isFalse);
    });
  });

  group('rata-rata dan sorotan', () {
    test('September: rata-rata 3 bulan; Makan +Rp295.000 (+31,1%) disorot, Belanja +8,8% tidak', () {
      final t = data();
      final comparison = compare(t, DateTime(2026, 9, 15))!;
      expect(comparison.months, 3);
      expect(comparison.toDay, isNull);
      final summary = summaryOf(t, DateTime(2026, 9), DateTime(2026, 10));

      final makan = comparison.ofGroup(summary.groupOf('cat:makan')!);
      expect(makan.isHigher, isTrue);
      expect(makan.difference, rp(295000));
      expect(makan.isNotable, isTrue);

      final belanja = comparison.ofGroup(summary.groupOf('cat:belanja')!);
      expect(belanja.difference, rp(248500));
      expect(belanja.isNotable, isFalse, reason: '<20%');

      final highlights = comparison.highlightsOf(summary);
      expect(highlights.map((h) => h.group.key), ['cat:makan']);
      expect(comparison.ofTotal(summary.total).difference, rp(295000 + 248500));
    });

    test('contoh §10 Oktober persis: rata-rata Rp340.000, selisih +Rp180.000 (+52,9%)', () {
      final t = [
        spend(DateTime(2026, 6), 1, 'belanja'), // bulan pertama pencatatan
        spend(DateTime(2026, 7, 3), 300000, 'makan'),
        spend(DateTime(2026, 7, 20), 650000, 'makan'),
        spend(DateTime(2026, 8, 4), 340000, 'makan'),
        spend(DateTime(2026, 8, 25), 660000, 'makan'),
        spend(DateTime(2026, 9, 2), 380000, 'makan'),
        spend(DateTime(2026, 9, 28), 865000, 'makan'),
        spend(DateTime(2026, 10, 4), 520000, 'makan'),
      ];
      final today = DateTime(2026, 10, 10, 9);
      final comparison = compare(t, today, today: today)!;
      final summary = summaryOf(t, DateTime(2026, 10), DateTime(2026, 11));
      final makan = comparison.ofGroup(summary.groupOf('cat:makan')!);
      // Juli, Agustus, September (Juni hanya Rp1 belanja): 3 bulan pembanding Jul–Sep.
      expect(makan.months, 3);
      expect(makan.baselineSum, rp(1020000));
      expect(makan.difference, rp(180000));
      expect(makan.isHigher, isTrue);
      expect(makan.isNotable, isTrue);
      expect(comparison.highlightsOf(summary).single.group.key, 'cat:makan');
    });

    test('periode pembanding lebih pendek (Feb) dihitung sampai hari terakhirnya', () {
      final t = [
        spend(DateTime(2026, 1, 31), 100000, 'makan'),
        spend(DateTime(2026, 2, 27), 200000, 'makan'),
        spend(DateTime(2026, 3, 30), 50000, 'makan'),
      ];
      final today = DateTime(2026, 3, 30, 9);
      final period = schedule.periodOf(today);
      final comparison = comparePeriod(
        transactions: t,
        period: period,
        periods: comparisonPeriods(period: period, schedule: schedule, earliestStart: DateTime(2026)),
        kind: CategoryKind.expense,
        categoryOf: categoryOf,
        today: today,
      )!;
      // s.d. tanggal 30: Februari penuh (sampai 28), Januari 1–30 (tanpa tgl 31).
      expect(comparison.sums['cat:makan'], rp(200000));
      expect(comparison.months, 2);
    });

    test('baru bulan ini: nominal > 0 di periode, 0 di semua pembanding; tidak disorot', () {
      final t = [...data(), spend(DateTime(2026, 9, 9), 400000, 'baru')];
      final comparison = compare(t, DateTime(2026, 9, 15))!;
      final summary = summaryOf(t, DateTime(2026, 9), DateTime(2026, 10));
      final baru = comparison.ofGroup(summary.groupOf('cat:baru')!);
      expect(baru.isNew, isTrue);
      expect(baru.hasBaseline, isFalse);
      expect(baru.isNotable, isFalse);
      expect(comparison.highlightsOf(summary).map((h) => h.group.key), ['cat:makan']);
    });

    test('ambang ganda: 25% tetapi Rp40.000 tidak disorot; Rp50.000 dan 20% tepat disorot', () {
      Comparison c(int now, int avg) => Comparison(amount: rp(now), baselineSum: rp(avg), months: 1);
      expect(c(200000, 160000).isNotable, isFalse, reason: '25% tetapi selisih Rp40.000');
      expect(c(300000, 250000).isNotable, isTrue, reason: '20% tepat dan Rp50.000 tepat');
      expect(c(2999999, 2500000).isNotable, isFalse, reason: 'sedikit di bawah 20%');
      expect(c(1000000, 900000).isNotable, isFalse, reason: 'Rp100.000 tetapi 11%');
      expect(c(100000, 200000).isNotable, isTrue, reason: 'turun juga disorot');
      expect(c(100000, 200000).isHigher, isFalse);
    });

    test('ambang nominal per mata uang: lima langkah pilihan cepat (rupiah Rp50.000, dolar lima)', () {
      expect(highlightMinSenOf(AppCurrency.idr), 5000000);
      expect(highlightMinSenOf(AppCurrency.usd), 500);
      // $4 lebih tinggi dari $10 = 40%, tetapi di bawah $5: tidak disorot; $6 disorot.
      final usd = highlightMinSenOf(AppCurrency.usd);
      expect(Comparison(amount: 1400, baselineSum: 1000, months: 1, minSen: usd).isNotable, isFalse);
      expect(Comparison(amount: 1600, baselineSum: 1000, months: 1, minSen: usd).isNotable, isTrue);
    });

    test('pembulatan hanya saat tampil: rata-rata 3 bulan tidak dibulatkan sebelum dibandingkan', () {
      // Jumlah 1.000 sen ÷ 3 = 333,33 sen; nominal 400 sen: selisih 66,67 → 67 sen.
      const c = Comparison(amount: 400, baselineSum: 1000, months: 3);
      expect(c.difference, 67);
      expect(const Comparison(amount: 400, baselineSum: 1001, months: 3).difference, 66);
    });

    test('maksimal tiga sorotan, urut selisih terbesar', () {
      final cats = [for (var i = 0; i < 5; i++) cat('k$i', 'K$i')];
      final map = {for (final c in cats) c.id: c};
      final t = <Transaction>[
        for (var i = 0; i < 5; i++) ...[
          spend(DateTime(2026, 8, 5), 1000000, 'k$i'),
          spend(DateTime(2026, 9, 5), 1000000 + (i + 1) * 100000, 'k$i'),
        ],
      ];
      final period = schedule.periodOf(DateTime(2026, 9, 15));
      final comparison = comparePeriod(
        transactions: t,
        period: period,
        periods: comparisonPeriods(period: period, schedule: schedule, earliestStart: DateTime(2026, 8)),
        kind: CategoryKind.expense,
        categoryOf: (id) => map[id],
      )!;
      final summary = summarizePeriod(
        t,
        from: DateTime(2026, 9),
        until: DateTime(2026, 10),
        kind: CategoryKind.expense,
        categoryOf: (id) => map[id],
      );
      final highlights = comparison.highlightsOf(summary);
      expect(highlights.length, 3);
      expect(highlights.map((h) => h.group.key), ['cat:k4', 'cat:k3', 'cat:k2']);
    });
  });
}
