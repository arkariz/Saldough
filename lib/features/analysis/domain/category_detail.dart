import 'package:dependencies/dependencies.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/analysis/domain/period_comparison.dart';
import 'package:saldough/features/analysis/domain/period_summary.dart';
import 'package:saldough/features/analysis/domain/period_trend.dart';
import 'package:saldough/features/analysis/domain/summarize_period.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Kunci kelompok Freelance di Analisis (`AnalysisGroup.key`).
const freelanceGroupKey = 'freelance';

/// Kunci kelompok kategori [id] di Analisis (`AnalysisGroup.key`).
String categoryGroupKey(String id) => 'cat:$id';

/// Satu kolom tren satu kategori: nominalnya di satu periode.
final class CategoryTrendPoint extends Equatable {
  /// Membuat [CategoryTrendPoint].
  const CategoryTrendPoint({
    required this.period,
    required this.amount,
    this.asOf,
  });

  /// Periodenya.
  final FinancialPeriod period;

  /// Nominal kategori itu di [period] (sen).
  final int amount;

  /// Hari ini bila [period] sedang berjalan, selain itu `null`.
  final DateTime? asOf;

  /// Periode ini belum selesai.
  bool get isRunning => asOf != null;

  @override
  List<Object?> get props => [period, amount, asOf];
}

/// Ringkasan frekuensi (B-17): jumlah transaksi dan rata-rata per transaksi,
/// dibanding biasanya.
final class CategoryFrequency extends Equatable {
  /// Membuat [CategoryFrequency].
  const CategoryFrequency({
    required this.count,
    required this.average,
    this.usualCountTenths,
    this.usualAverage,
  });

  /// Jumlah transaksi di periode ini.
  final int count;

  /// Rata-rata per transaksi (sen), dibulatkan setengah ke atas; 0 bila tanpa transaksi.
  final int average;

  /// Jumlah transaksi biasanya dalam persepuluhan (17 = 1,7); `null` tanpa
  /// bulan pembanding atau tanpa transaksi di bulan pembanding.
  final int? usualCountTenths;

  /// Nominal biasanya per transaksi (sen): total ÷ jumlah transaksi bulan
  /// pembanding (digabung, bukan rata-rata dari rata-rata); `null` bila tak ada.
  final int? usualAverage;

  @override
  List<Object?> get props => [count, average, usualCountTenths, usualAverage];
}

/// Rincian satu kategori (atau Freelance) untuk satu periode (T-19.5, A5).
final class CategoryDetail extends Equatable {
  /// Membuat [CategoryDetail].
  const CategoryDetail({
    required this.amount,
    required this.share,
    required this.trend,
    required this.frequency,
    this.comparison,
    this.compareToDay,
    this.average,
  });

  /// Total kategori di periode yang dilihat (sen).
  final int amount;

  /// Porsi dari total jenisnya (B-8).
  final AnalysisShare share;

  /// Tren enam periode berakhir di periode yang dilihat, dari yang tertua.
  final List<CategoryTrendPoint> trend;

  /// Frekuensi transaksi.
  final CategoryFrequency frequency;

  /// Pembanding headline (periode berjalan s.d. hari yang sama, B-6); `null`
  /// tanpa bulan pembanding.
  final Comparison? comparison;

  /// Tanggal hari ini bila [comparison] membandingkan periode berjalan s.d.
  /// hari yang sama, selain itu `null` (menentukan label pembanding).
  final int? compareToDay;

  /// Tinggi garis rata-rata di grafik: rata-rata bulan penuh pada bulan
  /// pembanding (sen); `null` bila tanpa bulan pembanding atau semuanya nol
  /// ("baru bulan ini", B-17).
  final int? average;

  @override
  List<Object?> get props => [
    amount,
    share,
    trend,
    frequency,
    comparison,
    compareToDay,
    average,
  ];
}

int _roundDiv(int numerator, int denominator) => (numerator * 2 + denominator) ~/ (2 * denominator);

/// Merangkum kategori [key] (`AnalysisGroup.key`: `cat:<id>` atau `freelance`)
/// pada [period] (FINANCIAL_ANALYSIS F4, B-17).
///
/// [trendPeriodList] dan [comparisonPeriodList] berasal dari [trendPeriods] dan
/// [comparisonPeriods]. Garis rata-rata memakai bulan pembanding **penuh**;
/// pembanding headline dan frekuensi biasanya memakai jendela yang sama dengan
/// Analisis (s.d. hari yang sama untuk periode berjalan, B-6).
CategoryDetail summarizeCategory({
  required Iterable<Transaction> transactions,
  required FinancialPeriod period,
  required List<FinancialPeriod> trendPeriodList,
  required List<FinancialPeriod> comparisonPeriodList,
  required String key,
  required CategoryKind kind,
  required Category? Function(String id) categoryOf,
  required DateTime today,
  String? walletId,
  int minSen = highlightMinSen,
}) {
  PeriodSummary summaryOf(FinancialPeriod p) => summarizePeriod(
    transactions,
    from: p.start,
    until: p.end,
    kind: kind,
    categoryOf: categoryOf,
    walletId: walletId,
  );
  AnalysisGroup? leafOf(PeriodSummary summary) {
    for (final group in summary.groups) {
      for (final leaf in group.kind == AnalysisGroupKind.others ? group.children : [group]) {
        if (leaf.key == key) return leaf;
      }
    }
    return null;
  }

  final trend = <CategoryTrendPoint>[];
  PeriodSummary? viewed;
  for (final p in trendPeriodList) {
    final summary = summaryOf(p);
    if (identical(p, period) || p.start == period.start) viewed = summary;
    trend.add(
      CategoryTrendPoint(
        period: p,
        amount: leafOf(summary)?.amount ?? 0,
        asOf: p.contains(today) ? today : null,
      ),
    );
  }
  viewed ??= summaryOf(period);
  final now = leafOf(viewed);
  final amount = now?.amount ?? 0;
  final count = now?.count ?? 0;

  final isRunning = period.contains(today);
  final comparison = comparePeriod(
    transactions: transactions,
    period: period,
    periods: comparisonPeriodList,
    kind: kind,
    categoryOf: categoryOf,
    today: isRunning ? today : null,
    walletId: walletId,
    minSen: minSen,
  );

  int? average;
  if (comparisonPeriodList.isNotEmpty) {
    final byStart = {
      for (final point in trend) point.period.start: point.amount,
    };
    final sum = comparisonPeriodList.fold(
      0,
      (s, p) => s + (byStart[p.start] ?? 0),
    );
    if (sum > 0) average = _roundDiv(sum, comparisonPeriodList.length);
  }

  final usualCount = comparison?.counts[key] ?? 0;
  final usualSum = comparison?.sums[key] ?? 0;
  return CategoryDetail(
    amount: amount,
    share: AnalysisShare.of(amount, viewed.total),
    trend: trend,
    frequency: CategoryFrequency(
      count: count,
      average: count == 0 ? 0 : _roundDiv(amount, count),
      usualCountTenths: comparison == null || usualCount == 0 ? null : _roundDiv(usualCount * 10, comparison.months),
      usualAverage: usualCount == 0 ? null : _roundDiv(usualSum, usualCount),
    ),
    comparison: comparison == null
        ? null
        : Comparison(
            amount: amount,
            baselineSum: usualSum,
            months: comparison.months,
            minSen: minSen,
          ),
    compareToDay: comparison?.toDay,
    average: average,
  );
}
