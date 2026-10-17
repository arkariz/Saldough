import 'package:dependencies/dependencies.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/analysis/domain/summarize_period.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Jumlah kolom tren (F6).
const trendSlots = 6;

/// Satu kolom tren: pemasukan dan pengeluaran satu periode (FINANCIAL_ANALYSIS F6).
final class TrendPoint extends Equatable {
  /// Membuat [TrendPoint].
  const TrendPoint({
    required this.period,
    required this.income,
    required this.expense,
    this.asOf,
  });

  /// Periodenya.
  final FinancialPeriod period;

  /// Total pemasukan (sen), sama dengan total Analisis Pemasukan periode itu.
  final int income;

  /// Total pengeluaran (sen), sama dengan total Analisis Pengeluaran periode itu.
  final int expense;

  /// Hari ini bila periode ini sedang berjalan (belum selesai), selain itu `null`.
  final DateTime? asOf;

  /// Periode ini sedang berjalan: selisihnya tidak bertanda sampai periodenya selesai.
  bool get isRunning => asOf != null;

  /// Selisih pemasukan dikurangi pengeluaran (sen, bisa negatif).
  int get net => income - expense;

  @override
  List<Object?> get props => [period, income, expense, asOf];
}

/// Periode tren untuk [period]: sampai enam periode berakhir di [period]
/// (urut dari yang tertua), tidak lebih awal dari [earliestStart] (periode
/// bulan pertama pencatatan, F6 langkah 3). Periode peralihan ikut.
List<FinancialPeriod> trendPeriods({
  required FinancialPeriod period,
  required FinancialMonthSchedule schedule,
  required DateTime earliestStart,
}) {
  final periods = [period];
  var cursor = period;
  while (periods.length < trendSlots) {
    cursor = schedule.previousOf(cursor);
    if (cursor.start.isBefore(earliestStart)) break;
    periods.insert(0, cursor);
  }
  return periods;
}

/// Total pemasukan dan pengeluaran tiap periode di [periods], dibatasi ke
/// [walletId] bila ada. Periode yang memuat [today] ditandai berjalan.
List<TrendPoint> buildTrend({
  required Iterable<Transaction> transactions,
  required List<FinancialPeriod> periods,
  required DateTime today,
  required Category? Function(String id) categoryOf,
  String? walletId,
}) {
  int totalOf(FinancialPeriod p, CategoryKind kind) => summarizePeriod(
    transactions,
    from: p.start,
    until: p.end,
    kind: kind,
    categoryOf: categoryOf,
    walletId: walletId,
  ).total;

  return [
    for (final p in periods)
      TrendPoint(
        period: p,
        income: totalOf(p, CategoryKind.income),
        expense: totalOf(p, CategoryKind.expense),
        asOf: p.contains(today) ? today : null,
      ),
  ];
}
