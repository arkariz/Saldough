import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/analysis/domain/category_detail.dart';
import 'package:saldough/features/analysis/domain/period_comparison.dart';
import 'package:saldough/features/analysis/domain/period_trend.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Rincian kategori (T-19.5, B-17) dengan contoh §10: Makan September
/// 2 transaksi Rp622.500, biasanya 1,7 transaksi Rp570.000, garis Rp950.000,
/// Rp295.000 di atas rata-rata.
void main() {
  int rp(int rupiah) => rupiah * 100;
  final schedule = FinancialMonthSchedule.initial;
  const makan = Category(id: 'makan', kind: CategoryKind.expense, name: 'Makan');
  const baru = Category(id: 'baru', kind: CategoryKind.expense, name: 'Kesehatan');
  const gaji = Category(id: 'gaji', kind: CategoryKind.income, name: 'Gaji');
  final all = {
    for (final c in [makan, baru, gaji]) c.id: c,
  };
  Category? categoryOf(String id) => all[id];

  var next = 0;
  ExpenseTransaction spend(DateTime date, int rupiah, String category) => ExpenseTransaction(
    id: 'e${next++}',
    date: date,
    amount: rp(rupiah),
    note: '',
    walletId: 'bca',
    categoryId: category,
  );

  // Transaksi Makan: Jun 1, Jul 2, Agt 2, Sep 2 (data uji QA, §10).
  List<Transaction> food() => [
    spend(DateTime(2026, 6, 5), 900000, 'makan'),
    spend(DateTime(2026, 7, 5), 450000, 'makan'),
    spend(DateTime(2026, 7, 20), 500000, 'makan'),
    spend(DateTime(2026, 8, 4), 400000, 'makan'),
    spend(DateTime(2026, 8, 25), 600000, 'makan'),
    spend(DateTime(2026, 9, 5), 380000, 'makan'),
    spend(DateTime(2026, 9, 20), 865000, 'makan'),
    // Sisa pengeluaran September supaya Makan = 11%.
    spend(DateTime(2026, 9, 10), 10175700, 'baru'),
  ];

  CategoryDetail detail(
    List<Transaction> t,
    DateTime viewed, {
    String key = 'cat:makan',
    DateTime? today,
    DateTime? earliestStart,
  }) {
    final earliest = earliestStart ?? DateTime(2026, 6);
    final period = schedule.periodOf(viewed);
    return summarizeCategory(
      transactions: t,
      period: period,
      trendPeriodList: trendPeriods(period: period, schedule: schedule, earliestStart: earliest),
      comparisonPeriodList: comparisonPeriods(period: period, schedule: schedule, earliestStart: earliest),
      key: key,
      kind: CategoryKind.expense,
      categoryOf: categoryOf,
      today: today ?? DateTime(2026, 10, 10, 9),
    );
  }

  test('Makan September: total, persen, frekuensi, biasanya, garis rata-rata, selisih (B-17)', () {
    final d = detail(food(), DateTime(2026, 9, 15));
    expect(d.amount, rp(1245000));
    expect(d.share.percent, 11);
    expect(d.frequency.count, 2);
    expect(d.frequency.average, rp(622500));
    expect(d.frequency.usualCountTenths, 17, reason: '5 transaksi ÷ 3 bulan = 1,7');
    expect(d.frequency.usualAverage, rp(570000), reason: 'Rp2.850.000 ÷ 5, digabung');
    expect(d.average, rp(950000));
    expect(d.comparison!.difference, rp(295000));
    expect(d.comparison!.isHigher, isTrue);
    expect(d.compareToDay, isNull);
    expect(d.trend.map((p) => p.amount), [rp(900000), rp(950000), rp(1000000), rp(1245000)]);
    expect(d.trend.map((p) => p.period.start.month), [6, 7, 8, 9]);
    expect(d.trend.any((p) => p.isRunning), isFalse);
  });

  test('periode berjalan: pembanding s.d. tanggal yang sama, garis tetap bulan penuh, kolom terakhir berjalan', () {
    final t = [...food(), spend(DateTime(2026, 10, 4), 520000, 'makan'), spend(DateTime(2026, 7, 3), 300000, 'makan')];
    final d = detail(t, DateTime(2026, 10, 10), today: DateTime(2026, 10, 10, 9));
    expect(d.compareToDay, 10);
    expect(d.trend.last.isRunning, isTrue);
    expect(d.trend.last.asOf, DateTime(2026, 10, 10, 9));
    // Garis: rata-rata Jul–Sep penuh (Jul Rp1.250.000 dengan transaksi tambahan, Agt Rp1.000.000, Sep Rp1.245.000).
    expect(d.average, (rp(1250000) + rp(1000000) + rp(1245000)) ~/ 3);
    // Headline: s.d. tanggal 10 saja (Jul 450k+300k tgl 3 & 5, Agt 400k, Sep 380k).
    expect(d.comparison!.baselineSum, rp(450000 + 300000) + rp(400000) + rp(380000));
    expect(d.comparison!.months, 3);
  });

  test('kategori baru bulan ini: tanpa garis rata-rata dan tanpa "biasanya"', () {
    final d = detail(
      [spend(DateTime(2026, 6), 1000, 'makan'), spend(DateTime(2026, 9, 21), 350000, 'baru')],
      DateTime(2026, 9, 15),
      key: 'cat:baru',
    );
    expect(d.amount, rp(350000));
    expect(d.comparison!.isNew, isTrue);
    expect(d.average, isNull);
    expect(d.frequency.usualCountTenths, isNull);
    expect(d.frequency.usualAverage, isNull);
    expect(d.frequency.count, 1);
  });

  test('bulan pertama pencatatan: tanpa pembanding, tren satu kolom', () {
    final d = detail([spend(DateTime(2026, 6, 5), 900000, 'makan')], DateTime(2026, 6, 15));
    expect(d.comparison, isNull);
    expect(d.average, isNull);
    expect(d.trend.length, 1);
  });

  test('Freelance: pemasukan pembayaran freelance tanpa kategori', () {
    final t = [
      IncomeTransaction(
        id: 'f1',
        date: DateTime(2026, 9, 26),
        amount: rp(2615438),
        note: '',
        walletId: 'bca',
        freelancePaymentId: 'p1',
      ),
      IncomeTransaction(
        id: 'g1',
        date: DateTime(2026, 9, 25),
        amount: rp(12000000),
        note: '',
        walletId: 'bca',
        categoryId: 'gaji',
      ),
    ];
    final period = schedule.periodOf(DateTime(2026, 9, 15));
    final d = summarizeCategory(
      transactions: t,
      period: period,
      trendPeriodList: [period],
      comparisonPeriodList: const [],
      key: freelanceGroupKey,
      kind: CategoryKind.income,
      categoryOf: categoryOf,
      today: DateTime(2026, 10, 10),
    );
    expect(d.amount, rp(2615438));
    expect(d.share.percent, 18);
    expect(d.frequency.count, 1);
  });
}
