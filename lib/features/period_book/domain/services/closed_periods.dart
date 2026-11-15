import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Transaksi minimal di periode tertutup agar ada Kartu Periode dan ajakan
/// Tutup buku (BP-2, BP-20).
const periodCardMinTransactions = 3;

/// Periode yang **sudah berakhir** dan punya ≥1 transaksi (BP-3), terbaru di
/// atas. Fakta bersama buku, kartu, dan Rak (ADR-045 §3.6).
///
/// Keanggotaan periode memakai `periodDateOf` lalu `financialPeriodOf`, sama
/// dengan Analisis dan Beranda, jadi periode peralihan (ADR-038) ikut sebagai
/// periodenya sendiri. Periode berjalan tidak punya buku. Periode kosong tidak
/// ada di daftar. Murni: tanpa jam global dan tanpa penyimpanan.
List<ClosedPeriod> closedPeriodsOf({
  required Iterable<Transaction> transactions,
  required FinancialMonthSchedule schedule,
  required DateTime today,
}) {
  final day = DateTime(today.year, today.month, today.day);
  final byStart = <DateTime, ({FinancialPeriod period, int count})>{};
  for (final t in transactions) {
    final period = financialPeriodOf(periodDateOf(t), schedule);
    if (day.isBefore(period.end)) continue; // masih berjalan (atau di masa depan)
    final entry = byStart[period.start];
    byStart[period.start] = (period: period, count: (entry?.count ?? 0) + 1);
  }
  return [
    for (final e in byStart.values) ClosedPeriod(period: e.period, transactionCount: e.count),
  ]..sort((a, b) => b.period.start.compareTo(a.period.start));
}

/// Periode tepat sebelum periode berjalan pada [today] (kandidat ajakan akhir
/// periode, BP-9: hanya periode terakhir).
FinancialPeriod previousPeriodOf(DateTime today, FinancialMonthSchedule schedule) {
  final current = financialPeriodOf(today, schedule);
  return financialPeriodOf(DateTime(current.start.year, current.start.month, current.start.day - 1), schedule);
}
