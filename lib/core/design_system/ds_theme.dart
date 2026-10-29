import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/color/ds_color_scheme.dart';
import 'package:saldough/core/design_system/presets/ds_theme_preset.dart';
import 'package:saldough/core/design_system/presets/ds_theme_presets.dart';
import 'package:saldough/core/design_system/tokens/ds_elevation.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';
import 'package:saldough/core/design_system/tokens/ds_shapes.dart';
import 'package:saldough/core/design_system/tokens/ds_spacing.dart';
import 'package:saldough/core/design_system/typography/ds_fonts.dart';
import 'package:saldough/core/design_system/typography/ds_typography.dart';

/// Pembangun [ThemeData] design system baru (ADR-043).
///
/// Belum dipasang ke `MaterialApp`; aplikasi masih memakai `PixelTheme`
/// sampai rombak UI. Tema komponen di sini hanya konfigurasi widget bawaan
/// Material sesuai spek, bukan widget baru.
abstract final class DsTheme {
  DsTheme._();

  static final Map<(String, Brightness), ThemeData> _cache = {};

  /// Tema preset bawaan mode terang.
  static ThemeData get light => build(DsThemePresets.fallback, Brightness.light);

  /// Tema preset bawaan mode gelap.
  static ThemeData get dark => build(DsThemePresets.fallback, Brightness.dark);

  /// Tema [preset] untuk [brightness]. Hasilnya disimpan, jadi memanggil
  /// ulang dengan argumen sama mengembalikan objek yang sama.
  static ThemeData build(DsThemePreset preset, Brightness brightness) =>
      _cache.putIfAbsent((preset.id, brightness), () => _build(preset, brightness));

  static ThemeData _build(DsThemePreset preset, Brightness brightness) {
    final colors = brightness == Brightness.light ? preset.light : preset.dark;
    final typography = DsTypography.from(colors);
    final elevation = DsElevation.from(colors, brightness);
    final textTheme = typography.toTextTheme();
    final button = typography.button;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors.toMaterial(brightness),
      textTheme: textTheme,
      fontFamily: DsFonts.body,
      scaffoldBackgroundColor: colors.surfaceCanvas,
      canvasColor: colors.surfaceCanvas,
      dividerColor: colors.outlineSubtle,
      disabledColor: colors.textTertiary,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      focusColor: colors.focusRing,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [colors, typography, elevation],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surfaceCanvas,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: typography.headlineSm,
      ),
      // Tombol utama: amber, teks kanvas; ditekan menggelap + garis dasar.
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(
          textStyle: button,
          background: colors.actionPrimary,
          backgroundPressed: colors.actionPrimaryPressed,
          foreground: colors.onActionPrimary,
          pressedSide: BorderSide(color: colors.actionPrimaryStroke),
          disabledBackground: colors.surfaceContainerHigh,
          disabledForeground: colors.textTertiary,
        ),
      ),
      // Tombol sekunder: terakota lembut.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(
          textStyle: button,
          background: colors.actionSecondary,
          backgroundPressed: colors.actionSecondaryPressed,
          foreground: colors.onActionSecondary,
          disabledBackground: colors.surfaceContainerHigh,
          disabledForeground: colors.textTertiary,
        ),
      ),
      // Tombol tersier: wadah + garis halus.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(
          textStyle: button,
          background: colors.surfaceContainer,
          backgroundPressed: colors.surfaceContainerHigh,
          foreground: colors.textPrimary,
          side: BorderSide(color: colors.outlineSubtle),
          disabledBackground: colors.surfaceContainer,
          disabledForeground: colors.textTertiary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: button,
          minimumSize: const Size(DsSpacing.minTapTarget, DsSpacing.minTapTarget),
          shape: DsShapes.control,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceCanvas,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: typography.bodyMd.copyWith(color: colors.textTertiary),
        labelStyle: typography.bodyMd.copyWith(color: colors.textSecondary),
        floatingLabelStyle: typography.labelMd.copyWith(color: colors.primary),
        helperStyle: typography.bodySm.copyWith(color: colors.textSecondary),
        errorStyle: typography.bodySm.copyWith(color: colors.error),
        suffixStyle: typography.labelMd.copyWith(color: colors.textSecondary),
        prefixStyle: typography.labelMd.copyWith(color: colors.textSecondary),
        border: _fieldBorder(colors.outlineStrong),
        enabledBorder: _fieldBorder(colors.outlineStrong),
        focusedBorder: _fieldBorder(colors.actionPrimary),
        errorBorder: _fieldBorder(colors.error),
        focusedErrorBorder: _fieldBorder(colors.error),
        disabledBorder: _fieldBorder(colors.outlineSubtle),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.actionPrimary,
        selectionHandleColor: colors.actionPrimary,
        selectionColor: colors.secondaryContainer,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: DsShapes.micro,
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide(color: colors.actionSecondary, width: 1.5)
              : BorderSide(color: colors.outlineStrong, width: 1.5),
        ),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.actionSecondary : colors.surfaceCanvas,
        ),
        checkColor: WidgetStatePropertyAll(colors.surfaceCanvas),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.actionSecondary : colors.outlineStrong,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.surfaceCanvas : colors.outlineStrong,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.actionSecondary : colors.surfaceContainerHigh,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.actionSecondary : colors.outlineStrong,
        ),
      ),
      // Chip bawaan = chip washi netral; varian terakota dan amber dibuat
      // saat komponen chip dirancang.
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        selectedColor: colors.secondaryContainer,
        side: BorderSide(color: colors.outlineSubtle),
        shape: DsShapes.control,
        labelStyle: typography.labelMd.copyWith(color: colors.textPrimary),
        secondaryLabelStyle: typography.labelMd.copyWith(color: colors.onSecondaryContainer),
        checkmarkColor: colors.onSecondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: DsSpacing.sm, vertical: DsSpacing.xs),
      ),
      cardTheme: CardThemeData(
        color: elevation.tier1.color,
        surfaceTintColor: Colors.transparent,
        shadowColor: colors.shadow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: DsRadius.lgAll,
          side: BorderSide(color: elevation.tier1.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: elevation.tier3.color,
        surfaceTintColor: Colors.transparent,
        barrierColor: colors.scrim,
        elevation: 0,
        titleTextStyle: typography.headlineSm,
        contentTextStyle: typography.bodyMd.copyWith(color: colors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: DsRadius.lgAll, side: BorderSide(color: elevation.tier3.border)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: elevation.tier3.color,
        modalBackgroundColor: elevation.tier3.color,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: colors.scrim,
        elevation: 0,
        shape: DsShapes.sheet,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: elevation.tier3.color,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: typography.bodyMd,
        shape: RoundedRectangleBorder(borderRadius: DsRadius.lgAll, side: BorderSide(color: elevation.tier3.border)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.inverseSurface,
        contentTextStyle: typography.bodySm.copyWith(color: colors.inverseOnSurface),
        actionTextColor: colors.inversePrimary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: DsShapes.card,
      ),
      dividerTheme: DividerThemeData(color: colors.outlineSubtle, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colors.secondaryContainer,
        indicatorShape: DsShapes.control,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => typography.labelMd.copyWith(
            color: states.contains(WidgetState.selected) ? colors.primary : colors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? colors.primary : colors.textSecondary,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: colors.surfaceContainerLow,
        iconColor: colors.textSecondary,
        textColor: colors.textPrimary,
        titleTextStyle: typography.bodyMd,
        subtitleTextStyle: typography.bodySm.copyWith(color: colors.textSecondary),
        leadingAndTrailingTextStyle: typography.amountMd,
      ),
      iconTheme: IconThemeData(color: colors.textPrimary),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.actionPrimary,
        linearTrackColor: colors.surfaceContainerHigh,
        circularTrackColor: colors.surfaceContainerHigh,
      ),
    );
  }

  static ButtonStyle _buttonStyle({
    required TextStyle textStyle,
    required Color background,
    required Color backgroundPressed,
    required Color foreground,
    required Color disabledBackground,
    required Color disabledForeground,
    BorderSide? side,
    BorderSide? pressedSide,
  }) {
    return ButtonStyle(
      textStyle: WidgetStatePropertyAll(textStyle),
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(Size(DsSpacing.minTapTarget, DsSpacing.minTapTarget)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: DsSpacing.md)),
      shape: const WidgetStatePropertyAll(DsShapes.control),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabledBackground;
        if (states.contains(WidgetState.pressed)) return backgroundPressed;
        return background;
      }),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? disabledForeground : foreground,
      ),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed) && pressedSide != null) return pressedSide;
        return side;
      }),
    );
  }

  // Sudut bawaan OutlineInputBorder sudah 4px = DsRadius.base.
  static OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(borderSide: BorderSide(color: color));
}

/// Akses singkat ke ekstensi design system dari [BuildContext].
extension DsThemeContext on BuildContext {
  /// Token design system tema aktif. Jatuh ke preset bawaan mode terang bila
  /// ekstensinya belum terpasang (aplikasi masih memakai tema lama), jadi
  /// tidak pernah melempar.
  DsTokens get ds {
    final theme = Theme.of(this);
    final colors = theme.extension<DsColorScheme>();
    final typography = theme.extension<DsTypography>();
    final elevation = theme.extension<DsElevation>();
    if (colors != null && typography != null && elevation != null) {
      return DsTokens(colors: colors, typography: typography, elevation: elevation);
    }
    final fallback = DsTheme.light;
    return DsTokens(
      colors: fallback.extension<DsColorScheme>()!,
      typography: fallback.extension<DsTypography>()!,
      elevation: fallback.extension<DsElevation>()!,
    );
  }
}

/// Kumpulan token tema aktif, dari `context.ds`.
@immutable
class DsTokens {
  /// Membuat kumpulan token.
  const DsTokens({required this.colors, required this.typography, required this.elevation});

  /// Skema warna.
  final DsColorScheme colors;

  /// Skala teks.
  final DsTypography typography;

  /// Tingkat permukaan.
  final DsElevation elevation;
}
