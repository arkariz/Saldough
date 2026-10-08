import 'package:flutter/material.dart';
import 'package:saldough/core/theme/extensions/app_colors.dart';
import 'package:saldough/core/theme/extensions/app_number_styles.dart';
import 'package:saldough/core/theme/tokens/app_radius.dart';
import 'package:saldough/core/theme/tokens/app_size.dart';

/// Tema global aplikasi ([ADR-031](docs/02-architecture/adr/0031-pixeltheme-jadi-tema-global.md),
/// isinya [ADR-034](docs/02-architecture/adr/0034-bahasa-visual-buku-catatan-piksel.md)):
/// token [AppColors.light]/[AppColors.dark], satu huruf Plus Jakarta Sans
/// (skala Teks design system), dan angka tabular di [AppNumberStyles].
///
/// Dipasang sekali sebagai `theme`/`darkTheme` `MaterialApp`; layar dan rute
/// tidak membungkus dirinya sendiri dengan tema.
abstract final class PixelTheme {
  PixelTheme._();

  /// Tema mode terang.
  static ThemeData get light => _build(AppColors.light, Brightness.light);

  /// Tema mode gelap.
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final base = brightness == Brightness.light ? ThemeData.light() : ThemeData.dark();
    // Pemetaan `flutter.md` design system.
    final colorScheme = (brightness == Brightness.light ? const ColorScheme.light() : const ColorScheme.dark()).copyWith(
      brightness: brightness,
      surface: colors.surface,
      onSurface: colors.ink,
      onSurfaceVariant: colors.ink2,
      surfaceContainerHighest: colors.surface2,
      primary: colors.brand,
      onPrimary: colors.onBrand,
      error: colors.danger,
      onError: colors.surface,
      outline: colors.lineStrong,
      outlineVariant: colors.line,
      inverseSurface: colors.inverseSurface,
      onInverseSurface: colors.onInverse,
      inversePrimary: colors.inverseBrand,
      scrim: colors.scrim,
    );
    final textTheme = buildTextTheme(colors);

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: colors.bg,
      colorScheme: colorScheme,
      textTheme: textTheme,
      dividerColor: colors.line,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      focusColor: colors.focus,
      disabledColor: colors.ink3,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: colors.scrim,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      // Kartu rata tanpa bingkai dan bayangan (design system bagian Bentuk).
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.pixelStep)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: AppSize.topbar,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colors.brand,
          foregroundColor: colors.onBrand,
          minimumSize: const Size(AppSize.touch, AppSize.button),
          textStyle: textTheme.titleMedium,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.pixelStepSm)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: AppSize.navbar,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? colors.brand : colors.ink2,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.line, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colors.onInverse),
        actionTextColor: colors.inverseBrand,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.pixelStep)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        barrierColor: colors.scrim,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: colors.ink2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.pixelStep)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        headerForegroundColor: colors.ink,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.pixelStep)),
        dividerColor: colors.line,
      ),
      extensions: [colors, AppNumberStyles.from(colors)],
    );
  }

  /// Skala Teks design system (`tokens.json` grup Teks) dipetakan ke slot
  /// [TextTheme] sesuai `flutter.md`. Slot yang tidak punya padanan diisi
  /// gaya terdekat supaya widget Material bawaan tidak jatuh ke huruf lain.
  static TextTheme buildTextTheme(AppColors colors) {
    final headline = appTextStyle(24, 32, FontWeight.w700, colors.ink, letterSpacing: -0.24);
    final title = appTextStyle(18, 26, FontWeight.w700, colors.ink);
    final bodyStrong = appTextStyle(16, 24, FontWeight.w600, colors.ink);
    final body = appTextStyle(16, 24, FontWeight.w400, colors.ink);
    final bodySm = appTextStyle(14, 20, FontWeight.w400, colors.ink2);
    final label = appTextStyle(14, 20, FontWeight.w600, colors.ink);
    final labelSm = appTextStyle(12, 16, FontWeight.w600, colors.ink2, letterSpacing: 0.12);
    final caption = appTextStyle(12, 16, FontWeight.w500, colors.ink2);

    return TextTheme(
      displayLarge: headline,
      displayMedium: headline,
      displaySmall: headline,
      headlineLarge: headline,
      headlineMedium: headline,
      headlineSmall: headline,
      titleLarge: title,
      titleMedium: bodyStrong,
      titleSmall: label,
      bodyLarge: body,
      bodyMedium: bodySm,
      bodySmall: caption,
      labelLarge: label,
      labelMedium: labelSm,
      labelSmall: labelSm,
    );
  }
}

/// Nama keluarga huruf satu-satunya aplikasi (didaftarkan di `pubspec.yaml`).
const String kAppFontFamily = 'PlusJakartaSans';

/// Ukuran teks terkecil di aplikasi (`caption`/`label-sm`, design system
/// bagian Tipografi).
const double kMinLabelSize = 12;

/// Gaya Plus Jakarta Sans dengan tinggi baris [lineHeight] dalam piksel.
///
/// Berkas hurufnya variabel, jadi bobot juga dikirim sebagai sumbu `wght`
/// lewat [TextStyle.fontVariations]; tanpa itu sebagian mesin render memakai
/// bobot bawaan berkas.
TextStyle appTextStyle(
  double fontSize,
  double lineHeight,
  FontWeight weight,
  Color color, {
  double? letterSpacing,
  bool tabular = false,
}) {
  return TextStyle(
    fontFamily: kAppFontFamily,
    fontFamilyFallback: const ['Roboto'],
    fontSize: fontSize,
    height: lineHeight / fontSize,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    letterSpacing: letterSpacing,
    color: color,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );
}
