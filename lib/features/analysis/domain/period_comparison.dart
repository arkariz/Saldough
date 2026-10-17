import 'package:dependencies/dependencies.dart';
import 'package:saldough/core/currency/app_currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/analysis/domain/period_summary.dart';
import 'package:saldough/features/analysis/domain/summarize_period.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Paling banyak periode pembanding (B-6).
const comparisonMonths = 3;

/// Ambang sorotan (B-7): selisih paling sedikit 20% dari rata-rata **dan**
/// Rp50.000 (dalam sen).
/// Selisih paling sedikit, dalam persen dari rata-rata.
const highlightMinPercent = 20;

/// Selisih paling sedikit, dalam sen, untuk rupiah (Rp50.000).
const highlightMinSen = 5000000;

/// Ambang nominal sorotan untuk [currency] (KT-A3): lima langkah pilihan cepat
/// mata uangnya, yang untuk rupiah tepat Rp50.000 (5 × Rp10.000).
int highlightMinSenOf(AppCurrency currency) => 5 * currency.step * 100;

/// Paling banyak sorotan di atas daftar (B-7).
const highlightMaxCount = 3;

/// Periode pembanding untuk [period] (FINANCIAL_ANALYSIS B-6): sampai tiga
/// periode tepat sebelumnya yang tidak lebih awal dari [earliestStart]
/// (periode pencatatan pertama). Periode peralihan dibuang dari pembanding
/// (tidak diganti periode yang lebih lama), dan bila [period] sendiri
/// peralihan, tidak ada pembanding. Urut dari yang terbaru.
List<FinancialPeriod> comparisonPeriods({
  required FinancialPeriod period,
  required FinancialMonthSchedule schedule,
  required DateTime earliestStart,
}) {
  if (period.isTransition) return const [];
  final periods = <FinancialPeriod>[];
  var cursor = period;
  for (var i = 0; i < comparisonMonths; i++) {
    cursor = schedule.previousOf(cursor);
    if (cursor.start.isBefore(earliestStart)) break;
    if (!cursor.isTransition) periods.add(cursor);
  }
  return periods;
}

/// Selisih satu angka terhadap rata-rata bulan pembanding (B-6, B-7).
///
/// Dihitung dengan bilangan bulat murni: rata-rata = [baselineSum] ÷ [months]
/// tidak pernah dibulatkan sebelum dibandingkan; pembulatan setengah ke atas
/// hanya untuk [difference] yang ditampilkan.
final class Comparison extends Equatable {
  /// Membuat [Comparison] untuk [amount] terhadap jumlah [baselineSum] dari
  /// [months] bulan pembanding.
  const Comparison({
    required this.amount,
    required this.baselineSum,
    required this.months,
    this.minSen = highlightMinSen,
  });

  /// Nominal periode yang dilihat (sen).
  final int amount;

  /// Jumlah nominal yang sama di seluruh bulan pembanding (sen).
  final int baselineSum;

  /// Banyaknya bulan pembanding (≥ 1).
  final int months;

  /// Ambang selisih nominal untuk sorotan (sen).
  final int minSen;

  /// Bernilai di periode ini tetapi 0 di semua bulan pembanding: "baru bulan ini".
  bool get isNew => baselineSum == 0 && amount > 0;

  /// Ada rata-rata (> 0) untuk dibandingkan.
  bool get hasBaseline => baselineSum > 0;

  /// Nominal lebih tinggi dari rata-rata (sama dihitung naik).
  bool get isHigher => amount * months >= baselineSum;

  int get _scaled => (amount * months - baselineSum).abs();

  /// Besar selisih terhadap rata-rata, dibulatkan setengah ke atas (sen, ≥ 0).
  int get difference => (_scaled * 2 + months) ~/ (2 * months);

  /// Layak disorot: selisih ≥ 20% **dan** ≥ [minSen] dari rata-rata (> 0).
  bool get isNotable =>
      hasBaseline && _scaled * 100 >= highlightMinPercent * baselineSum && _scaled >= minSen * months;

  @override
  List<Object?> get props => [amount, baselineSum, months, minSen];
}

/// Satu sorotan: kategori (atau Freelance) beserta selisihnya (B-7).
final class Highlight extends Equatable {
  /// Membuat [Highlight].
  const Highlight({required this.group, required this.comparison});

  /// Baris yang disorot (kategori atau Freelance, bukan Lainnya).
  final AnalysisGroup group;

  /// Selisih terhadap rata-ratanya.
  final Comparison comparison;

  @override
  List<Object?> get props => [group, comparison];
}

/// Pembanding satu periode terhadap bulan pembanding (B-6): rata-rata per
/// baris dan total, dasar sorotan (B-7).
final class PeriodComparison extends Equatable {
  /// Membuat [PeriodComparison].
  const PeriodComparison({
    required this.months,
    required this.toDay,
    required this.totalSum,
    required this.sums,
    this.minSen = highlightMinSen,
  });

  /// Banyaknya bulan pembanding (≥ 1).
  final int months;

  /// Periode berjalan dibandingkan sampai tanggal ini; `null` untuk periode selesai.
  final int? toDay;

  /// Jumlah total jenis di seluruh bulan pembanding (sen).
  final int totalSum;

  /// Jumlah per kunci baris daun (`AnalysisGroup.key` kategori, `freelance`,
  /// `uncategorized`) di seluruh bulan pembanding. Kunci yang tak ada = 0.
  final Map<String, int> sums;

  /// Ambang selisih nominal sorotan (sen), mengikuti mata uang aktif.
  final int minSen;

  /// Pembanding [total] jenis terhadap total bulan pembanding.
  Comparison ofTotal(int total) => Comparison(amount: total, baselineSum: totalSum, months: months, minSen: minSen);

  /// Pembanding [group]. Lainnya dibandingkan sebagai gabungan anggotanya.
  Comparison ofGroup(AnalysisGroup group) {
    final baseline = group.kind == AnalysisGroupKind.others
        ? group.children.fold(0, (sum, g) => sum + (sums[g.key] ?? 0))
        : sums[group.key] ?? 0;
    return Comparison(amount: group.amount, baselineSum: baseline, months: months, minSen: minSen);
  }

  /// Sorotan (B-7) untuk [summary]: kategori dan Freelance bernominal > 0 dan
  /// berpembanding > 0 dengan selisih ≥ 20% dan ≥ Rp50.000, paling banyak
  /// tiga, urut selisih terbesar. Tanpa kategori dan Lainnya tidak disorot.
  List<Highlight> highlightsOf(PeriodSummary summary) {
    final leaves = [
      for (final g in summary.groups)
        if (g.kind == AnalysisGroupKind.others) ...g.children else g,
    ].where((g) => g.kind == AnalysisGroupKind.category || g.kind == AnalysisGroupKind.freelance);
    final highlights = [
      for (final g in leaves)
        if (g.amount > 0 && ofGroup(g).isNotable) Highlight(group: g, comparison: ofGroup(g)),
    ]..sort((a, b) {
        final byDiff = b.comparison.difference.compareTo(a.comparison.difference);
        return byDiff != 0 ? byDiff : a.group.sortName.compareTo(b.group.sortName);
      });
    return highlights.take(highlightMaxCount).toList();
  }

  @override
  List<Object?> get props => [months, toDay, totalSum, sums, minSen];
}

/// Membandingkan [period] dengan [periods] (hasil [comparisonPeriods]); `null`
/// bila tidak ada pembanding. Periode berjalan ([today] tidak `null`) hanya
/// dihitung sampai hari yang sama di tiap periode pembanding, atau hari
/// terakhirnya bila lebih pendek (B-6).
PeriodComparison? comparePeriod({
  required Iterable<Transaction> transactions,
  required FinancialPeriod period,
  required List<FinancialPeriod> periods,
  required CategoryKind kind,
  required Category? Function(String id) categoryOf,
  DateTime? today,
  String? walletId,
  int minSen = highlightMinSen,
}) {
  if (periods.isEmpty) return null;
  final elapsed = today == null ? null : _utcDay(today).difference(_utcDay(period.start)).inDays + 1;
  var totalSum = 0;
  final sums = <String, int>{};
  for (final p in periods) {
    var until = p.end;
    if (elapsed != null) {
      final cut = DateTime(p.start.year, p.start.month, p.start.day + elapsed);
      if (cut.isBefore(until)) until = cut;
    }
    final summary = summarizePeriod(
      transactions,
      from: p.start,
      until: until,
      kind: kind,
      categoryOf: categoryOf,
      walletId: walletId,
    );
    totalSum += summary.total;
    for (final g in summary.groups) {
      for (final leaf in g.kind == AnalysisGroupKind.others ? g.children : [g]) {
        sums[leaf.key] = (sums[leaf.key] ?? 0) + leaf.amount;
      }
    }
  }
  return PeriodComparison(months: periods.length, toDay: today?.day, totalSum: totalSum, sums: sums, minSen: minSen);
}

DateTime _utcDay(DateTime d) => DateTime.utc(d.year, d.month, d.day);
