import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/color/ds_color_scheme.dart';
import 'package:saldough/core/design_system/presets/ds_theme_preset.dart';
import 'package:saldough/core/design_system/tokens/ds_elevation.dart';
import 'package:saldough/core/design_system/typography/ds_typography.dart';
import 'package:saldough/core/theme/theme.dart';

/// Jembatan sementara antara design system v2 dan layar yang belum dirombak
/// (ADR-043 §3.1, direvisi 30 Okt 2026).
///
/// Layar lama membaca `context.appColors`, `context.numberStyles`, dan
/// `Theme.of(context).textTheme`; bila ekstensinya tidak ada, keduanya jatuh
/// ke token terang sehingga mode gelap rusak diam-diam. Jembatan ini
/// membangun tema lama (`PixelTheme.forColors`) dari warna preset aktif,
/// lalu menambahkan ekstensi Ds di atasnya, jadi layar lama dan widget Ds
/// hidup berdampingan di tema yang sama.
///
/// Hapus saat seluruh layar sudah memakai `context.ds` (T-24.4).
abstract final class AppThemeBridge {
  AppThemeBridge._();

  static final Map<(String, Brightness), ThemeData> _cache = {};

  /// Tema [preset] untuk [brightness]; hasilnya disimpan.
  static ThemeData build(DsThemePreset preset, Brightness brightness) =>
      _cache.putIfAbsent((preset.id, brightness), () => _build(preset, brightness));

  static ThemeData _build(DsThemePreset preset, Brightness brightness) {
    final colors = brightness == Brightness.light ? preset.light : preset.dark;
    final base = PixelTheme.forColors(legacyColorsFrom(colors), brightness);
    return base.copyWith(
      extensions: [
        ...base.extensions.values,
        colors,
        DsTypography.from(colors),
        DsElevation.from(colors, brightness),
      ],
    );
  }

  /// Memetakan 52 token lama dari peran design system v2.
  ///
  /// `lineStrong` memakai `outline`, bukan `outlineStrong`: garis kolom
  /// isian lama wajib ≥ 3:1, sedangkan bingkai Ds sengaja ikut spek
  /// (KT-DS1). `brandSoft`/`brandInk` memakai wadah sekunder supaya preset
  /// non-hijau tidak memunculkan warna sage.
  static AppColors legacyColorsFrom(DsColorScheme c) {
    final k = c.categories;
    return AppColors(
      bg: c.surfaceCanvas,
      surface: c.surfaceCard,
      surface2: c.surfaceSunken,
      surface3: c.surfaceContainerHigh,
      surfaceRaised: c.surfaceCard,
      line: c.outlineSubtle,
      lineStrong: c.outline,
      track: c.surfaceContainerHigh,
      ink: c.textPrimary,
      ink2: c.textSecondary,
      ink3: c.textMuted,
      brand: c.actionPrimary,
      brandPressed: c.actionPrimaryPressed,
      brandDeep: c.actionPrimaryPressed,
      onBrand: c.onActionPrimary,
      brandSoft: c.secondaryContainer,
      brandInk: c.onSecondaryContainer,
      straw: c.heroAccentWarm,
      positive: c.income,
      positiveSoft: c.incomeContainer,
      danger: c.error,
      dangerSoft: c.errorContainer,
      warning: c.warning,
      warningSoft: c.warningContainer,
      warningFill: c.warning,
      info: c.info,
      infoSoft: c.infoContainer,
      inverseSurface: c.inverseSurface,
      onInverse: c.inverseOnSurface,
      inverseBrand: c.inversePrimary,
      focus: c.outlineFocus,
      scrim: c.scrim,
      catOrangeBg: k.orange.container,
      catOrange: k.orange.color,
      catGreenBg: k.green.container,
      catGreen: k.green.color,
      catBlueBg: k.blue.container,
      catBlue: k.blue.color,
      catPurpleBg: k.purple.container,
      catPurple: k.purple.color,
      catTealBg: k.teal.container,
      catTeal: k.teal.color,
      catRoseBg: k.rose.container,
      catRose: k.rose.color,
      catAmberBg: k.amber.container,
      catAmber: k.amber.color,
      catIndigoBg: k.indigo.container,
      catIndigo: k.indigo.color,
      catBrownBg: k.brown.container,
      catBrown: k.brown.color,
      catSlateBg: k.slate.container,
      catSlate: k.slate.color,
    );
  }
}
