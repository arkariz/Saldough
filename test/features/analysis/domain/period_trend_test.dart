import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/analysis/domain/period_trend.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Tren enam periode (T-19.4, FINANCIAL_ANALYSIS F6): periode berakhir di yang
/// dilihat, tidak sebelum pencatatan pertama, total sama dengan Analisis.
void main() {
  int rp(int rupiah) => rupiah * 100;
  final schedule = FinancialMonthSchedule.initial;
  Category? categoryOf(String id) => null;

  var next = 0;
  ExpenseTransaction spend(DateTime date, int rupiah, {String wallet = 'bca'}) =>
      ExpenseTransaction(id: 'e${next++}', date: date, amount: rp(rupiah), note: '', walletId: wallet);
  IncomeTransaction earn(DateTime date, int rupiah, {String wallet = 'bca'}) =>
      IncomeTransaction(id: 'i${next++}', date: date, amount: rp(rupiah), note: '', walletId: wallet);

  group('trendPeriods', () {
    test('enam periode berakhir di periode yang dilihat, tertua dulu', () {
      final periods = trendPeriods(
        period: schedule.periodOf(DateTime(2026, 10, 10)),
        schedule: schedule,
        earliestStart: DateTime(2026),
      );
      expect(periods.map((p) => p.start), [
        DateTime(2026, 5),
        DateTime(2026, 6),
        DateTime(2026, 7),
        DateTime(2026, 8),
        DateTime(2026, 9),
        DateTime(2026, 10),
      ]);
    });

    test('tidak lebih awal dari bulan pertama pencatatan (bukan nol)', () {
      final periods = trendPeriods(
        period: schedule.periodOf(DateTime(2026, 9, 15)),
        schedule: schedule,
        earliestStart: DateTime(2026, 6),
      );
      expect(periods.map((p) => p.start), [DateTime(2026, 6), DateTime(2026, 7), DateTime(2026, 8), DateTime(2026, 9)]);
    });

    test('periode tunggal bila yang dilihat bulan pertama pencatatan', () {
      final periods = trendPeriods(
        period: schedule.periodOf(DateTime(2026, 6, 15)),
        schedule: schedule,
        earliestStart: DateTime(2026, 6),
      );
      expect(periods.length, 1);
    });

    test('periode peralihan ikut, dengan keterangan panjangnya', () {
      final changed = schedule.changedOn(DateTime(2026, 10, 10), const FinancialMonthStart.day(25));
      final periods = trendPeriods(
        period: changed.periodOf(DateTime(2026, 11)),
        schedule: changed,
        earliestStart: DateTime(2026, 8),
      );
      expect(periods.map((p) => p.isTransition), [false, false, true, false]);
      expect(periods[2].days, 24);
    });
  });

  group('buildTrend', () {
    final data = [
      earn(DateTime(2026, 8, 25), 12000000),
      spend(DateTime(2026, 8, 5), 8000000),
      earn(DateTime(2026, 9, 25), 14000000, wallet: 'tabungan'),
      spend(DateTime(2026, 9, 5), 9000000),
      spend(DateTime(2026, 9, 6), 100000, wallet: 'tabungan'),
      TransferTransaction(
        id: 't${next++}',
        date: DateTime(2026, 9, 7),
        amount: rp(1000000),
        note: '',
        fromWalletId: 'bca',
        toWalletId: 'tabungan',
      ),
    ];
    final periods = [DateTime(2026, 8), DateTime(2026, 9)].map(schedule.periodOf).toList();

    test('pemasukan dan pengeluaran per periode; transfer tidak dihitung; selisih = pemasukan − pengeluaran', () {
      final trend = buildTrend(transactions: data, periods: periods, today: DateTime(2026, 10, 10), categoryOf: categoryOf);
      expect(trend.map((p) => p.income), [rp(12000000), rp(14000000)]);
      expect(trend.map((p) => p.expense), [rp(8000000), rp(9100000)]);
      expect(trend.map((p) => p.net), [rp(4000000), rp(4900000)]);
      expect(trend.any((p) => p.isRunning), isFalse);
    });

    test('periode yang memuat hari ini berjalan dan membawa tanggalnya', () {
      final today = DateTime(2026, 9, 20, 9);
      final trend = buildTrend(transactions: data, periods: periods, today: today, categoryOf: categoryOf);
      expect(trend.map((p) => p.isRunning), [false, true]);
      expect(trend.last.asOf, today);
    });

    test('satu dompet: hanya transaksi dompet itu', () {
      final trend = buildTrend(
        transactions: data,
        periods: periods,
        today: DateTime(2026, 10, 10),
        categoryOf: categoryOf,
        walletId: 'tabungan',
      );
      expect(trend.map((p) => p.income), [0, rp(14000000)]);
      expect(trend.map((p) => p.expense), [0, rp(100000)]);
    });
  });
}
