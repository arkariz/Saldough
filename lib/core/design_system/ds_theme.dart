import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/color/ds_color_scheme.dart';
import 'package:saldough/core/design_system/presets/ds_theme_preset.dart';
import 'package:saldough/core/design_system/presets/ds_theme_presets.dart';
import 'package:saldough/core/design_system/tokens/ds_elevation.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
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
      fontFamily: DsFonts.sans,
      scaffoldBackgroundColor: colors.surfaceCanvas,
      canvasColor: colors.surfaceCanvas,
      dividerColor: colors.outlineSubtle,
      disabledColor: colors.textTertiary,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      focusColor: colors.outlineFocus,
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
      // Tombol utama: hijau matcha, teks putih.
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(
          textStyle: button,
          background: colors.actionPrimary,
          backgroundPressed: colors.actionPrimaryPressed,
          foreground: colors.onActionPrimary,
          disabledBackground: colors.surfaceSunken,
          disabledForeground: colors.textTertiary,
        ),
      ),
      // Tombol sekunder: putih, garis rambut; ditekan bingkai menggelap.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(
          textStyle: button,
          background: colors.actionSecondary,
          backgroundPressed: colors.actionSecondaryPressed,
          foreground: colors.onActionSecondary,
          side: BorderSide(color: colors.outlineSubtle),
          pressedSide: BorderSide(color: colors.outlineStrong),
          disabledBackground: colors.actionSecondary,
          disabledForeground: colors.textTertiary,
        ),
      ),
      // Tombol hantu: tanpa bingkai dan latar.
      textButtonTheme: TextButtonThemeData(
        style: _buttonStyle(
          textStyle: button,
          background: Colors.transparent,
          backgroundPressed: colors.actionGhostPressed,
          foreground: colors.actionGhost,
          disabledBackground: Colors.transparent,
          disabledForeground: colors.textTertiary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: typography.bodyMd.copyWith(color: colors.textTertiary),
        labelStyle: typography.bodyMd.copyWith(color: colors.textSecondary),
        floatingLabelStyle: typography.labelMd.copyWith(color: colors.outlineFocus),
        helperStyle: typography.bodySm.copyWith(color: colors.textSecondary),
        errorStyle: typography.bodySm.copyWith(color: colors.error),
        prefixStyle: typography.bodyMd.copyWith(color: colors.textTertiary),
        suffixStyle: typography.bodyMd.copyWith(color: colors.textTertiary),
        border: _fieldBorder(colors.outlineSubtle),
        enabledBorder: _fieldBorder(colors.outlineSubtle),
        focusedBorder: _fieldBorder(colors.outlineFocus),
        errorBorder: _fieldBorder(colors.error),
        focusedErrorBorder: _fieldBorder(colors.error),
        disabledBorder: _fieldBorder(colors.outlineSubtle),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.actionPrimary,
        selectionHandleColor: colors.actionPrimary,
        selectionColor: colors.incomeContainer,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: DsShapes.micro,
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide(color: colors.actionPrimary)
              : BorderSide(color: colors.outlineStrong),
        ),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.actionPrimary : colors.surfaceCard,
        ),
        checkColor: WidgetStatePropertyAll(colors.onActionPrimary),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.actionPrimary : colors.outlineStrong,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.onActionPrimary : colors.surfaceCard,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.actionPrimary : colors.outlineStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      // Kontrol segmen: track kabut, segmen terpilih putih bergaris rambut.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(typography.labelMd),
          shape: const WidgetStatePropertyAll(DsShapes.badge),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.selected) ? colors.outlineSubtle : Colors.transparent,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? colors.surfaceCard : colors.surfaceSunken,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? colors.textPrimary : colors.textSecondary,
          ),
        ),
      ),
      // Chip bawaan = chip pilihan pil (mis. filter). Badge dan tag
      // bersudut 6px dibuat di komponen badge (KT-DS4).
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceCard,
        selectedColor: colors.incomeContainer,
        side: BorderSide(color: colors.outlineSubtle),
        shape: DsShapes.pill,
        labelStyle: typography.labelMd.copyWith(color: colors.textSecondary),
        secondaryLabelStyle: typography.labelMd.copyWith(color: colors.onIncomeContainer),
        checkmarkColor: colors.onIncomeContainer,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: DsSpacing.xs),
      ),
      cardTheme: CardThemeData(
        color: elevation.card.color,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: DsRadius.lgAll, side: BorderSide(color: elevation.card.border)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: elevation.overlay.color,
        surfaceTintColor: Colors.transparent,
        barrierColor: colors.scrim,
        elevation: 0,
        titleTextStyle: typography.headlineSm,
        contentTextStyle: typography.bodyMd.copyWith(color: colors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: DsRadius.xlAll, side: BorderSide(color: elevation.overlay.border)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: elevation.overlay.color,
        modalBackgroundColor: elevation.overlay.color,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: colors.scrim,
        elevation: 0,
        shape: DsShapes.sheet,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: elevation.overlay.color,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: typography.bodyMd,
        shape: RoundedRectangleBorder(borderRadius: DsRadius.mdAll, side: BorderSide(color: elevation.overlay.border)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.inverseSurface,
        contentTextStyle: typography.bodyMd.copyWith(color: colors.inverseOnSurface),
        actionTextColor: colors.inversePrimary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: DsShapes.tile,
      ),
      dividerTheme: DividerThemeData(color: colors.outlineSubtle, thickness: 1, space: 1),
      // Navigasi bawah: kanvas, label piksel, tab aktif hijau.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => typography.pixelCaption.copyWith(
            color: states.contains(WidgetState.selected) ? colors.actionPrimary : colors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 21,
            color: states.contains(WidgetState.selected) ? colors.actionPrimary : colors.textSecondary,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: colors.surfaceHover,
        iconColor: colors.textSecondary,
        textColor: colors.textPrimary,
        titleTextStyle: typography.titleMd,
        subtitleTextStyle: typography.bodySm.copyWith(color: colors.textSecondary),
        leadingAndTrailingTextStyle: typography.pixelAmount,
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
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
      shape: const WidgetStatePropertyAll(DsShapes.control),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      animationDuration: DsMotion.standard,
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

  static OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
    borderRadius: DsRadius.baseAll,
    borderSide: BorderSide(color: color),
  );
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
