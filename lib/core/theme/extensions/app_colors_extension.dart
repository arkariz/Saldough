import 'package:flutter/material.dart';

/// Slot warna semantik Saldough, dipasang lewat [ThemeData.extensions].
///
/// Enam slot keuangan (`income`, `expense`, `overBudget`, `investment`,
/// `rollUp`, `needsReview`) plus slot netral untuk panel/teks/skeleton.
/// Nilai hex dan perannya didokumentasikan di ADR-0006 — jangan menulis
/// warna harfiah di widget, selalu lewat `context.appColors`.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  /// Membuat [AppColorsExtension] dengan seluruh slot wajib diisi.
  const AppColorsExtension({
    required this.income,
    required this.expense,
    required this.overBudget,
    required this.investment,
    required this.rollUp,
    required this.needsReview,
    required this.onNeedsReview,
    required this.background,
    required this.cardBackground,
    required this.edge,
    required this.textPrimary,
    required this.textMuted,
    required this.divider,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  /// Nominal masuk, dan sisa siklus yang positif.
  final Color income;

  /// Nominal keluar.
  final Color expense;

  /// Sisa siklus yang negatif. Jangan pakai [expense] untuk ini.
  final Color overBudget;

  /// Pos tujuan dan alokasi dana investasi.
  final Color investment;

  /// Baris yang nominalnya dihitung dari sumber lain (roll-up belanja/kartu).
  final Color rollUp;

  /// Baris hasil rollover yang belum ditinjau/dikonfirmasi pemilik.
  final Color needsReview;

  /// Warna teks/ikon di atas isian [needsReview].
  final Color onNeedsReview;

  /// Dasar layar.
  final Color background;

  /// Dasar panel/kartu.
  final Color cardBackground;

  /// Garis tepi tebal khas panel komik.
  final Color edge;

  /// Teks utama.
  final Color textPrimary;

  /// Teks sekunder/keterangan — tingkat ketiga hierarki teks.
  final Color textMuted;

  /// Pemisah baris di dalam satu panel. Dipakai jarang — gaya komik lebih
  /// mengandalkan garis tepi tebal daripada garis pembagi tipis.
  final Color divider;

  /// Dasar skeleton loading.
  final Color shimmerBase;

  /// Kilau skeleton loading.
  final Color shimmerHighlight;

  /// Palet mode terang, nilai resmi dari ADR-0006.
  static const light = AppColorsExtension(
    income: Color(0xFF1E9E46),
    expense: Color(0xFFE13553),
    overBudget: Color(0xFFF07B12),
    investment: Color(0xFFD99B00),
    rollUp: Color(0xFF2D6FE0),
    needsReview: Color(0xFFFFD400),
    onNeedsReview: Color(0xFF161310),
    background: Color(0xFFF2E9D8),
    cardBackground: Color(0xFFFFFFFF),
    edge: Color(0xFF161310),
    textPrimary: Color(0xFF161310),
    textMuted: Color(0xFF5B5346),
    divider: Color(0x24161310),
    shimmerBase: Color(0xFFEFE6D2),
    shimmerHighlight: Color(0xFFFFFFFF),
  );

  /// Palet mode gelap, nilai resmi dari ADR-0006.
  static const dark = AppColorsExtension(
    income: Color(0xFF3DDC68),
    expense: Color(0xFFFF4D6A),
    overBudget: Color(0xFFFF8C3D),
    investment: Color(0xFFFFD23F),
    rollUp: Color(0xFF5B9CFF),
    needsReview: Color(0xFFFFE14D),
    onNeedsReview: Color(0xFF14120F),
    background: Color(0xFF0E0D0B),
    cardBackground: Color(0xFF1C1A17),
    edge: Color(0xFFF2E9D8),
    textPrimary: Color(0xFFF2E9D8),
    textMuted: Color(0xFFB9AF9E),
    divider: Color(0x2EF2E9D8),
    shimmerBase: Color(0xFF1C1A17),
    shimmerHighlight: Color(0xFF29271F),
  );

  @override
  AppColorsExtension copyWith({
    Color? income,
    Color? expense,
    Color? overBudget,
    Color? investment,
    Color? rollUp,
    Color? needsReview,
    Color? onNeedsReview,
    Color? background,
    Color? cardBackground,
    Color? edge,
    Color? textPrimary,
    Color? textMuted,
    Color? divider,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return AppColorsExtension(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      overBudget: overBudget ?? this.overBudget,
      investment: investment ?? this.investment,
      rollUp: rollUp ?? this.rollUp,
      needsReview: needsReview ?? this.needsReview,
      onNeedsReview: onNeedsReview ?? this.onNeedsReview,
      background: background ?? this.background,
      cardBackground: cardBackground ?? this.cardBackground,
      edge: edge ?? this.edge,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      overBudget: Color.lerp(overBudget, other.overBudget, t)!,
      investment: Color.lerp(investment, other.investment, t)!,
      rollUp: Color.lerp(rollUp, other.rollUp, t)!,
      needsReview: Color.lerp(needsReview, other.needsReview, t)!,
      onNeedsReview: Color.lerp(onNeedsReview, other.onNeedsReview, t)!,
      background: Color.lerp(background, other.background, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      edge: Color.lerp(edge, other.edge, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}

/// Akses singkat ke [AppColorsExtension] dari [BuildContext].
///
/// Jatuh ke [AppColorsExtension.light] kalau ekstensi belum terpasang,
/// sehingga tidak pernah melempar.
extension AppColorsContext on BuildContext {
  /// Slot warna semantik tema aktif.
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light;
}
