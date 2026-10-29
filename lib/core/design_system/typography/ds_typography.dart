import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/color/ds_color_scheme.dart';
import 'package:saldough/core/design_system/typography/ds_fonts.dart';

/// Skala teks design system baru (ADR-043).
///
/// Gaya Plus Jakarta Sans persis skala `spec.md` (px, `letterSpacing` em ×
/// ukuran). Gaya `pixel*` berhuruf Space Mono Bold dari referensi
/// komponen `reference/home.html`; Space Mono berlebar tetap, jadi digit
/// sudah sejajar tanpa fitur tabular. Nominal Plus Jakarta Sans memakai
/// angka tabular. Warna bawaan `textPrimary`; ubah lewat `copyWith`.
@immutable
class DsTypography extends ThemeExtension<DsTypography> {
  /// Membuat skala; semua gaya wajib diisi.
  const DsTypography({
    required this.displayLg,
    required this.headlineLg,
    required this.headlineLgMobile,
    required this.headlineMd,
    required this.headlineSm,
    required this.titleMd,
    required this.bodyLg,
    required this.bodyMd,
    required this.bodySm,
    required this.labelMd,
    required this.labelSm,
    required this.numericalDisplay,
    required this.amount,
    required this.amountSm,
    required this.pixelDisplay,
    required this.pixelAmount,
    required this.pixelLabel,
    required this.pixelCaption,
  });

  /// Skala dengan warna dari [colors].
  factory DsTypography.from(DsColorScheme colors) {
    final ink = colors.textPrimary;
    const sans = DsFonts.sans;
    const pixel = DsFonts.pixel;
    return DsTypography(
      displayLg: dsTextStyle(sans, 44, 52, FontWeight.w700, ink, letterSpacingEm: -0.03),
      headlineLg: dsTextStyle(sans, 32, 40, FontWeight.w600, ink, letterSpacingEm: -0.025),
      headlineLgMobile: dsTextStyle(sans, 26, 34, FontWeight.w600, ink, letterSpacingEm: -0.02),
      headlineMd: dsTextStyle(sans, 24, 32, FontWeight.w600, ink, letterSpacingEm: -0.02),
      headlineSm: dsTextStyle(sans, 18, 26, FontWeight.w600, ink, letterSpacingEm: -0.015),
      titleMd: dsTextStyle(sans, 16, 24, FontWeight.w600, ink, letterSpacingEm: -0.01),
      bodyLg: dsTextStyle(sans, 16, 26, FontWeight.w400, ink, letterSpacingEm: -0.005),
      bodyMd: dsTextStyle(sans, 14, 22, FontWeight.w400, ink),
      bodySm: dsTextStyle(sans, 13, 18, FontWeight.w400, ink, letterSpacingEm: 0.005),
      labelMd: dsTextStyle(sans, 12, 16, FontWeight.w600, ink, letterSpacingEm: 0.04),
      labelSm: dsTextStyle(sans, 11, 14, FontWeight.w600, ink, letterSpacingEm: 0.06),
      numericalDisplay: dsTextStyle(sans, 36, 44, FontWeight.w600, ink, letterSpacingEm: -0.03, tabular: true),
      amount: dsTextStyle(sans, 16, 24, FontWeight.w700, ink, tabular: true),
      amountSm: dsTextStyle(sans, 13, 18, FontWeight.w600, ink, tabular: true),
      pixelDisplay: dsTextStyle(pixel, 28, 36, FontWeight.w700, ink, letterSpacingEm: -0.025),
      pixelAmount: dsTextStyle(pixel, 12, 16, FontWeight.w700, ink),
      pixelLabel: dsTextStyle(pixel, 11, 14, FontWeight.w700, ink, letterSpacingEm: 0.05),
      pixelCaption: dsTextStyle(pixel, 10, 14, FontWeight.w700, ink, letterSpacingEm: 0.025),
    );
  }

  /// `display-lg`: 44/52 w700, −0,03em.
  final TextStyle displayLg;

  /// `headline-lg`: 32/40 w600, −0,025em.
  final TextStyle headlineLg;

  /// `headline-lg-mobile`: 26/34 w600, −0,02em.
  final TextStyle headlineLgMobile;

  /// `headline-md`: 24/32 w600, −0,02em.
  final TextStyle headlineMd;

  /// `headline-sm`: 18/26 w600, −0,015em.
  final TextStyle headlineSm;

  /// `title-md`: 16/24 w600, −0,01em. Judul baris transaksi dan kartu.
  final TextStyle titleMd;

  /// `body-lg`: 16/26, −0,005em.
  final TextStyle bodyLg;

  /// `body-md`: 14/22.
  final TextStyle bodyMd;

  /// `body-sm`: 13/18, +0,005em. Keterangan dan waktu.
  final TextStyle bodySm;

  /// `label-md`: 12/16 w600, +0,04em. Isi badge dan chip.
  final TextStyle labelMd;

  /// `label-sm`: 11/14 w600, +0,06em.
  final TextStyle labelSm;

  /// `numerical-display`: 36/44 w600, −0,03em, angka tabular. Kolom nominal.
  final TextStyle numericalDisplay;

  /// Nominal penting di kartu: 16/24 w700, angka tabular.
  final TextStyle amount;

  /// Nominal pendukung (kotak statistik): 13/18 w600, angka tabular.
  final TextStyle amountSm;

  /// Angka saldo kartu hero: Space Mono 28/36, −0,025em.
  final TextStyle pixelDisplay;

  /// Nominal baris transaksi: Space Mono 12/16.
  final TextStyle pixelAmount;

  /// Label kapital kepala kartu, badge, tombol ringkas, tautan "Semua": Space
  /// Mono 11/14, +0,05em.
  final TextStyle pixelLabel;

  /// Label kecil: navigasi bawah, tag kategori, keterangan jam: Space Mono
  /// 10/14, +0,025em.
  final TextStyle pixelCaption;

  /// Slot [TextTheme] Material dari skala ini, supaya widget bawaan memakai
  /// huruf design system.
  TextTheme toTextTheme() => TextTheme(
    displayLarge: displayLg,
    displayMedium: numericalDisplay,
    displaySmall: headlineLg,
    headlineLarge: headlineLgMobile,
    headlineMedium: headlineMd,
    headlineSmall: headlineSm,
    titleLarge: headlineSm,
    titleMedium: titleMd,
    titleSmall: bodyMd.copyWith(fontWeight: FontWeight.w600, fontVariations: _weight(FontWeight.w600)),
    bodyLarge: bodyLg,
    bodyMedium: bodyMd,
    bodySmall: bodySm,
    labelLarge: button,
    labelMedium: labelMd,
    labelSmall: labelSm,
  );

  /// Teks tombol: 14/20 w600 (spek tidak menyebut; referensi 13px semibold).
  TextStyle get button =>
      bodyMd.copyWith(height: 20 / 14, fontWeight: FontWeight.w600, fontVariations: _weight(FontWeight.w600));

  /// Seluruh gaya berikut namanya, untuk uji dan dokumentasi.
  Map<String, TextStyle> toMap() => {
    'displayLg': displayLg,
    'headlineLg': headlineLg,
    'headlineLgMobile': headlineLgMobile,
    'headlineMd': headlineMd,
    'headlineSm': headlineSm,
    'titleMd': titleMd,
    'bodyLg': bodyLg,
    'bodyMd': bodyMd,
    'bodySm': bodySm,
    'labelMd': labelMd,
    'labelSm': labelSm,
    'numericalDisplay': numericalDisplay,
    'amount': amount,
    'amountSm': amountSm,
    'pixelDisplay': pixelDisplay,
    'pixelAmount': pixelAmount,
    'pixelLabel': pixelLabel,
    'pixelCaption': pixelCaption,
  };

  @override
  DsTypography copyWith({
    TextStyle? displayLg,
    TextStyle? headlineLg,
    TextStyle? headlineLgMobile,
    TextStyle? headlineMd,
    TextStyle? headlineSm,
    TextStyle? titleMd,
    TextStyle? bodyLg,
    TextStyle? bodyMd,
    TextStyle? bodySm,
    TextStyle? labelMd,
    TextStyle? labelSm,
    TextStyle? numericalDisplay,
    TextStyle? amount,
    TextStyle? amountSm,
    TextStyle? pixelDisplay,
    TextStyle? pixelAmount,
    TextStyle? pixelLabel,
    TextStyle? pixelCaption,
  }) {
    return DsTypography(
      displayLg: displayLg ?? this.displayLg,
      headlineLg: headlineLg ?? this.headlineLg,
      headlineLgMobile: headlineLgMobile ?? this.headlineLgMobile,
      headlineMd: headlineMd ?? this.headlineMd,
      headlineSm: headlineSm ?? this.headlineSm,
      titleMd: titleMd ?? this.titleMd,
      bodyLg: bodyLg ?? this.bodyLg,
      bodyMd: bodyMd ?? this.bodyMd,
      bodySm: bodySm ?? this.bodySm,
      labelMd: labelMd ?? this.labelMd,
      labelSm: labelSm ?? this.labelSm,
      numericalDisplay: numericalDisplay ?? this.numericalDisplay,
      amount: amount ?? this.amount,
      amountSm: amountSm ?? this.amountSm,
      pixelDisplay: pixelDisplay ?? this.pixelDisplay,
      pixelAmount: pixelAmount ?? this.pixelAmount,
      pixelLabel: pixelLabel ?? this.pixelLabel,
      pixelCaption: pixelCaption ?? this.pixelCaption,
    );
  }

  @override
  DsTypography lerp(ThemeExtension<DsTypography>? other, double t) {
    if (other is! DsTypography) return this;
    return DsTypography(
      displayLg: TextStyle.lerp(displayLg, other.displayLg, t)!,
      headlineLg: TextStyle.lerp(headlineLg, other.headlineLg, t)!,
      headlineLgMobile: TextStyle.lerp(headlineLgMobile, other.headlineLgMobile, t)!,
      headlineMd: TextStyle.lerp(headlineMd, other.headlineMd, t)!,
      headlineSm: TextStyle.lerp(headlineSm, other.headlineSm, t)!,
      titleMd: TextStyle.lerp(titleMd, other.titleMd, t)!,
      bodyLg: TextStyle.lerp(bodyLg, other.bodyLg, t)!,
      bodyMd: TextStyle.lerp(bodyMd, other.bodyMd, t)!,
      bodySm: TextStyle.lerp(bodySm, other.bodySm, t)!,
      labelMd: TextStyle.lerp(labelMd, other.labelMd, t)!,
      labelSm: TextStyle.lerp(labelSm, other.labelSm, t)!,
      numericalDisplay: TextStyle.lerp(numericalDisplay, other.numericalDisplay, t)!,
      amount: TextStyle.lerp(amount, other.amount, t)!,
      amountSm: TextStyle.lerp(amountSm, other.amountSm, t)!,
      pixelDisplay: TextStyle.lerp(pixelDisplay, other.pixelDisplay, t)!,
      pixelAmount: TextStyle.lerp(pixelAmount, other.pixelAmount, t)!,
      pixelLabel: TextStyle.lerp(pixelLabel, other.pixelLabel, t)!,
      pixelCaption: TextStyle.lerp(pixelCaption, other.pixelCaption, t)!,
    );
  }

  static List<FontVariation> _weight(FontWeight weight) => [FontVariation.weight(weight.value.toDouble())];
}

/// Gaya teks design system baru: [lineHeight] dalam px, [letterSpacingEm]
/// dalam em (dikalikan [fontSize]).
///
/// Plus Jakarta Sans berkas variabel, jadi bobot juga dikirim lewat sumbu
/// `wght` ([TextStyle.fontVariations]); tanpa itu sebagian mesin render
/// memakai bobot bawaan berkas. Space Mono statis, sumbunya diabaikan.
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
    fontFeatures: tabular ? const [FontFeature.tabularFigures(), FontFeature('lnum')] : null,
  );
}
