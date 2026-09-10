import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saldough/core/theme/extensions/app_colors_extension.dart';
import 'package:saldough/core/theme/tokens/app_radius.dart';

/// Menyusun [ThemeData] terang dan gelap untuk Saldough.
///
/// Tiga peran huruf (lihat ADR-0006): Archivo Black untuk judul/angka besar,
/// Space Grotesk untuk teks dan komponen Material standar, Bangers untuk
/// label/badge pendek lewat [shout] — bukan bagian dari [TextTheme] baku
/// karena tidak ada slot Material yang cocok untuknya.
abstract final class AppTheme {
  AppTheme._();

  /// Gaya huruf "shout" (Bangers) untuk label/badge bergaya stiker komik.
  /// Selalu sertakan tumpukan cadangan nyata kalau font belum termuat.
  static TextStyle shout({double fontSize = 14, Color? color}) =>
      GoogleFonts.bangers(fontSize: fontSize, color: color, letterSpacing: 0.4);

  /// Tema mode terang.
  static ThemeData get lightTheme => _build(AppColorsExtension.light, Brightness.light);

  /// Tema mode gelap.
  static ThemeData get darkTheme => _build(AppColorsExtension.dark, Brightness.dark);

  static ThemeData _build(AppColorsExtension colors, Brightness brightness) {
    final base = brightness == Brightness.light ? ThemeData.light() : ThemeData.dark();
    final colorScheme = (brightness == Brightness.light
            ? const ColorScheme.light()
            : const ColorScheme.dark())
        .copyWith(
      brightness: brightness,
      surface: colors.cardBackground,
      onSurface: colors.textPrimary,
      primary: colors.income,
      onPrimary: brightness == Brightness.light ? Colors.white : colors.background,
      error: colors.expense,
      onError: Colors.white,
      outline: colors.edge,
    );

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(base.textTheme, colors),
      dividerColor: colors.divider,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      // Motif komik memakai bayangan keras kustom (AppCard/AppButton), tidak
      // pernah elevasi Material standar — lihat ADR-0006.
      cardTheme: CardThemeData(
        color: colors.cardBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: colors.edge, width: 2.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.archivoBlack(
          fontSize: 18,
          color: colors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colors.income,
          foregroundColor: brightness == Brightness.light ? Colors.white : colors.onNeedsReview,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smAll,
            side: BorderSide(color: colors.edge, width: 2.5),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.divider, thickness: 1, space: 1),
      extensions: [colors],
    );
  }

  // Dibangun slot per slot (bukan lewat `GoogleFonts.xxxTextTheme(base)`
  // lalu `.copyWith`) karena helper itu menimpa SELURUH slot termasuk yang
  // sudah diisi huruf lain kalau dipanggil berantai — lihat peran huruf di
  // ADR-0006: Archivo Black untuk display/headline, Space Grotesk untuk
  // sisanya.
  static TextTheme _buildTextTheme(TextTheme base, AppColorsExtension colors) {
    return base.copyWith(
      displayLarge: GoogleFonts.archivoBlack(textStyle: base.displayLarge, color: colors.textPrimary),
      displayMedium: GoogleFonts.archivoBlack(textStyle: base.displayMedium, color: colors.textPrimary),
      displaySmall: GoogleFonts.archivoBlack(textStyle: base.displaySmall, color: colors.textPrimary),
      headlineLarge: GoogleFonts.archivoBlack(textStyle: base.headlineLarge, color: colors.textPrimary),
      headlineMedium: GoogleFonts.archivoBlack(textStyle: base.headlineMedium, color: colors.textPrimary),
      headlineSmall: GoogleFonts.archivoBlack(textStyle: base.headlineSmall, color: colors.textPrimary),
      titleLarge: GoogleFonts.spaceGrotesk(textStyle: base.titleLarge, color: colors.textPrimary),
      titleMedium: GoogleFonts.spaceGrotesk(textStyle: base.titleMedium, color: colors.textPrimary),
      titleSmall: GoogleFonts.spaceGrotesk(textStyle: base.titleSmall, color: colors.textPrimary),
      bodyLarge: GoogleFonts.spaceGrotesk(textStyle: base.bodyLarge, color: colors.textPrimary),
      bodyMedium: GoogleFonts.spaceGrotesk(textStyle: base.bodyMedium, color: colors.textPrimary),
      bodySmall: GoogleFonts.spaceGrotesk(textStyle: base.bodySmall, color: colors.textMuted),
      labelLarge: GoogleFonts.spaceGrotesk(textStyle: base.labelLarge, color: colors.textPrimary),
      labelMedium: GoogleFonts.spaceGrotesk(textStyle: base.labelMedium, color: colors.textMuted),
      labelSmall: GoogleFonts.spaceGrotesk(textStyle: base.labelSmall, color: colors.textMuted),
    );
  }
}
