import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/color/ds_color_scheme.dart';
import 'package:saldough/core/design_system/typography/ds_fonts.dart';

/// Skala teks design system baru (ADR-043), persis spek Autumn Kyoto Ledger:
/// ukuran `rem` × 16, tinggi baris dalam px, `letterSpacing` `em` × ukuran.
///
/// Gaya `amount*` tidak ada di spek: nominal memakai JetBrains Mono dengan
/// angka tabular sesuai prosa spek ("pair financial tallies with
/// tabular-nums"). Warna bawaan `textPrimary`; ubah lewat `copyWith`.
@immutable
class DsTypography extends ThemeExtension<DsTypography> {
  /// Membuat skala; semua gaya wajib diisi.
  const DsTypography({
    required this.displayLg,
    required this.displayLgMobile,
    required this.headlineLg,
    required this.headlineLgMobile,
    required this.headlineMd,
    required this.headlineSm,
    required this.bodyLg,
    required this.bodyMd,
    required this.bodySm,
    required this.labelLg,
    required this.labelMd,
    required this.labelSm,
    required this.amountLg,
    required this.amountMd,
    required this.amountSm,
  });

  /// Skala dengan warna dari [colors].
  factory DsTypography.from(DsColorScheme colors) {
    final ink = colors.textPrimary;
    return DsTypography(
      displayLg: dsTextStyle(DsFonts.heading, 56, 64, FontWeight.w700, ink, letterSpacingEm: -0.03),
      displayLgMobile: dsTextStyle(DsFonts.heading, 36, 44, FontWeight.w700, ink, letterSpacingEm: -0.02),
      headlineLg: dsTextStyle(DsFonts.heading, 32, 40, FontWeight.w600, ink, letterSpacingEm: -0.02),
      headlineLgMobile: dsTextStyle(DsFonts.heading, 26, 34, FontWeight.w600, ink, letterSpacingEm: -0.015),
      headlineMd: dsTextStyle(DsFonts.heading, 24, 32, FontWeight.w600, ink, letterSpacingEm: -0.015),
      headlineSm: dsTextStyle(DsFonts.heading, 20, 28, FontWeight.w600, ink, letterSpacingEm: -0.01),
      bodyLg: dsTextStyle(DsFonts.body, 18, 28, FontWeight.w400, ink),
      bodyMd: dsTextStyle(DsFonts.body, 16, 24, FontWeight.w400, ink),
      bodySm: dsTextStyle(DsFonts.body, 14, 22, FontWeight.w400, ink),
      labelLg: dsTextStyle(DsFonts.mono, 14, 20, FontWeight.w500, ink, letterSpacingEm: 0.02),
      labelMd: dsTextStyle(DsFonts.mono, 12, 18, FontWeight.w500, ink, letterSpacingEm: 0.03),
      labelSm: dsTextStyle(DsFonts.mono, 11, 16, FontWeight.w500, ink, letterSpacingEm: 0.04),
      amountLg: dsTextStyle(DsFonts.mono, 28, 36, FontWeight.w600, ink, tabular: true),
      amountMd: dsTextStyle(DsFonts.mono, 16, 24, FontWeight.w500, ink, tabular: true),
      amountSm: dsTextStyle(DsFonts.mono, 14, 20, FontWeight.w500, ink, tabular: true),
    );
  }

  /// `display-lg`: Epilogue 56/64 w700, −0,03em.
  final TextStyle displayLg;

  /// `display-lg-mobile`: Epilogue 36/44 w700, −0,02em.
  final TextStyle displayLgMobile;

  /// `headline-lg`: Epilogue 32/40 w600, −0,02em.
  final TextStyle headlineLg;

  /// `headline-lg-mobile`: Epilogue 26/34 w600, −0,015em.
  final TextStyle headlineLgMobile;

  /// `headline-md`: Epilogue 24/32 w600, −0,015em.
  final TextStyle headlineMd;

  /// `headline-sm`: Epilogue 20/28 w600, −0,01em.
  final TextStyle headlineSm;

  /// `body-lg`: Source Sans 3 18/28.
  final TextStyle bodyLg;

  /// `body-md`: Source Sans 3 16/24.
  final TextStyle bodyMd;

  /// `body-sm`: Source Sans 3 14/22.
  final TextStyle bodySm;

  /// `label-lg`: JetBrains Mono 14/20 w500, +0,02em.
  final TextStyle labelLg;

  /// `label-md`: JetBrains Mono 12/18 w500, +0,03em. Juga satuan di kolom input.
  final TextStyle labelMd;

  /// `label-sm`: JetBrains Mono 11/16 w500, +0,04em.
  final TextStyle labelSm;

  /// Nominal utama: JetBrains Mono 28/36 w600, angka tabular.
  final TextStyle amountLg;

  /// Nominal baris daftar: JetBrains Mono 16/24 w500, angka tabular.
  final TextStyle amountMd;

  /// Nominal pendukung: JetBrains Mono 14/20 w500, angka tabular.
  final TextStyle amountSm;

  /// Slot [TextTheme] Material dari skala ini, supaya widget bawaan memakai
  /// huruf design system. `title*` tidak ada di spek: `titleLarge` =
  /// `headline-sm`, `titleMedium`/`titleSmall` = isi tebal.
  TextTheme toTextTheme() => TextTheme(
    displayLarge: displayLg,
    displayMedium: displayLgMobile,
    displaySmall: headlineLg,
    headlineLarge: headlineLgMobile,
    headlineMedium: headlineMd,
    headlineSmall: headlineSm,
    titleLarge: headlineSm,
    titleMedium: bodyMd.copyWith(fontWeight: FontWeight.w600, fontVariations: _weight(FontWeight.w600)),
    titleSmall: bodySm.copyWith(fontWeight: FontWeight.w600, fontVariations: _weight(FontWeight.w600)),
    bodyLarge: bodyLg,
    bodyMedium: bodyMd,
    bodySmall: bodySm,
    labelLarge: labelLg,
    labelMedium: labelMd,
    labelSmall: labelSm,
  );

  /// Gaya teks tombol: Source Sans 3 16/24 w600. Spek tidak menyebut huruf
  /// tombol; isi dipilih supaya label tindakan tetap terbaca seperti kalimat.
  TextStyle get button => bodyMd.copyWith(fontWeight: FontWeight.w600, fontVariations: _weight(FontWeight.w600));

  /// Seluruh gaya berikut namanya, untuk uji dan dokumentasi.
  Map<String, TextStyle> toMap() => {
    'displayLg': displayLg,
    'displayLgMobile': displayLgMobile,
    'headlineLg': headlineLg,
    'headlineLgMobile': headlineLgMobile,
    'headlineMd': headlineMd,
    'headlineSm': headlineSm,
    'bodyLg': bodyLg,
    'bodyMd': bodyMd,
    'bodySm': bodySm,
    'labelLg': labelLg,
    'labelMd': labelMd,
    'labelSm': labelSm,
    'amountLg': amountLg,
    'amountMd': amountMd,
    'amountSm': amountSm,
  };

  @override
  DsTypography copyWith({
    TextStyle? displayLg,
    TextStyle? displayLgMobile,
    TextStyle? headlineLg,
    TextStyle? headlineLgMobile,
    TextStyle? headlineMd,
    TextStyle? headlineSm,
    TextStyle? bodyLg,
    TextStyle? bodyMd,
    TextStyle? bodySm,
    TextStyle? labelLg,
    TextStyle? labelMd,
    TextStyle? labelSm,
    TextStyle? amountLg,
    TextStyle? amountMd,
    TextStyle? amountSm,
  }) {
    return DsTypography(
      displayLg: displayLg ?? this.displayLg,
      displayLgMobile: displayLgMobile ?? this.displayLgMobile,
      headlineLg: headlineLg ?? this.headlineLg,
      headlineLgMobile: headlineLgMobile ?? this.headlineLgMobile,
      headlineMd: headlineMd ?? this.headlineMd,
      headlineSm: headlineSm ?? this.headlineSm,
      bodyLg: bodyLg ?? this.bodyLg,
      bodyMd: bodyMd ?? this.bodyMd,
      bodySm: bodySm ?? this.bodySm,
      labelLg: labelLg ?? this.labelLg,
      labelMd: labelMd ?? this.labelMd,
      labelSm: labelSm ?? this.labelSm,
      amountLg: amountLg ?? this.amountLg,
      amountMd: amountMd ?? this.amountMd,
      amountSm: amountSm ?? this.amountSm,
    );
  }

  @override
  DsTypography lerp(ThemeExtension<DsTypography>? other, double t) {
    if (other is! DsTypography) return this;
    return DsTypography(
      displayLg: TextStyle.lerp(displayLg, other.displayLg, t)!,
      displayLgMobile: TextStyle.lerp(displayLgMobile, other.displayLgMobile, t)!,
      headlineLg: TextStyle.lerp(headlineLg, other.headlineLg, t)!,
      headlineLgMobile: TextStyle.lerp(headlineLgMobile, other.headlineLgMobile, t)!,
      headlineMd: TextStyle.lerp(headlineMd, other.headlineMd, t)!,
      headlineSm: TextStyle.lerp(headlineSm, other.headlineSm, t)!,
      bodyLg: TextStyle.lerp(bodyLg, other.bodyLg, t)!,
      bodyMd: TextStyle.lerp(bodyMd, other.bodyMd, t)!,
      bodySm: TextStyle.lerp(bodySm, other.bodySm, t)!,
      labelLg: TextStyle.lerp(labelLg, other.labelLg, t)!,
      labelMd: TextStyle.lerp(labelMd, other.labelMd, t)!,
      labelSm: TextStyle.lerp(labelSm, other.labelSm, t)!,
      amountLg: TextStyle.lerp(amountLg, other.amountLg, t)!,
      amountMd: TextStyle.lerp(amountMd, other.amountMd, t)!,
      amountSm: TextStyle.lerp(amountSm, other.amountSm, t)!,
    );
  }

  static List<FontVariation> _weight(FontWeight weight) => [FontVariation.weight(weight.value.toDouble())];
}

/// Gaya teks design system baru: [lineHeight] dalam px, [letterSpacingEm]
/// dalam em (dikalikan [fontSize]).
///
/// Berkas huruf variabel, jadi bobot juga dikirim lewat sumbu `wght`
/// ([TextStyle.fontVariations]); tanpa itu sebagian mesin render memakai
/// bobot bawaan berkas.
TextStyle dsTextStyle(
  String family,
  double fontSize,
  double lineHeight,
  FontWeight weight,
  Color color, {
  double letterSpacingEm = 0,
  bool tabular = false,
}) {
  return TextStyle(
    fontFamily: family,
    fontFamilyFallback: DsFonts.fallback,
    fontSize: fontSize,
    height: lineHeight / fontSize,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    letterSpacing: letterSpacingEm == 0 ? null : letterSpacingEm * fontSize,
    color: color,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );
}
