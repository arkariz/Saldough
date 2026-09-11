import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saldough/core/theme/extensions/app_colors_extension.dart';
import 'package:saldough/core/theme/tokens/app_border.dart';
import 'package:saldough/core/theme/tokens/app_radius.dart';

/// Menyusun [ThemeData] terang dan gelap untuk Saldough.
///
/// Tiga peran huruf (lihat ADR-0006): Archivo Black untuk judul/angka besar,
/// Space Grotesk untuk teks dan komponen Material standar, Bangers untuk
/// label/badge pendek lewat [shout] — bukan bagian dari [TextTheme] baku
/// karena tidak ada slot Material yang cocok untuknya.
///
/// Setiap gaya di bawah mendeklarasikan tumpukan huruf cadangan nyata lewat
/// [_withFallback] (ADR-0006 §Risiko: "setiap gaya teks wajib mendeklarasikan
/// tumpukan huruf cadangan yang nyata") — kalau `google_fonts` gagal
/// mengunduh saat peluncuran pertama tanpa koneksi, tampilan jatuh ke huruf
/// sistem yang MASIH sepadan perannya, bukan diam-diam ke huruf acak
/// (UX-28). Paket `GoogleFonts.*` sendiri tidak punya parameter
/// `fontFamilyFallback` passthrough — makanya ditambahkan lewat
/// `TextStyle.copyWith` setelah gaya dibuat, bukan sebagai argumen.
abstract final class AppTheme {
  AppTheme._();

  /// Tumpukan cadangan untuk peran Archivo Black (judul/angka besar) — huruf
  /// grotesk sangat tebal yang tersedia luas di Windows/Android.
  static const _displayFallback = ['Arial Black', 'Roboto', 'sans-serif'];

  /// Tumpukan cadangan untuk peran Space Grotesk (teks dan komponen
  /// Material standar) — grotesk netral yang tersedia di semua platform
  /// target (Android/iOS).
  static const _bodyFallback = ['Roboto', 'Helvetica Neue', 'Arial', 'sans-serif'];

  /// Tumpukan cadangan untuk peran Bangers (label/badge stiker komik) —
  /// huruf informal/tulisan tangan yang paling dekat perannya di tiap
  /// platform, bukan sekadar grotesk netral (yang akan kehilangan
  /// karakter "komik"-nya sama sekali).
  static const _shoutFallback = ['Comic Sans MS', 'Chalkboard SE', 'cursive'];

  /// Menambahkan tumpukan cadangan [fallback] ke [style] tanpa mengubah
  /// huruf utamanya.
  static TextStyle? _withFallback(TextStyle? style, List<String> fallback) =>
      style?.copyWith(fontFamilyFallback: fallback);

  /// Gaya huruf "shout" (Bangers) untuk label/badge bergaya stiker komik.
  static TextStyle shout({double fontSize = 14, Color? color}) => _withFallback(
        GoogleFonts.bangers(fontSize: fontSize, color: color, letterSpacing: 0.4),
        _shoutFallback,
      )!;

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
          side: BorderSide(color: colors.edge, width: AppBorder.thick),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _withFallback(
          GoogleFonts.archivoBlack(fontSize: 18, color: colors.textPrimary),
          _displayFallback,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colors.income,
          foregroundColor: brightness == Brightness.light ? Colors.white : colors.onNeedsReview,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smAll,
            side: BorderSide(color: colors.edge, width: AppBorder.thick),
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
    TextStyle? display(TextStyle? base, Color color) =>
        _withFallback(GoogleFonts.archivoBlack(textStyle: base, color: color), _displayFallback);
    TextStyle? body(TextStyle? base, Color color) =>
        _withFallback(GoogleFonts.spaceGrotesk(textStyle: base, color: color), _bodyFallback);

    return base.copyWith(
      displayLarge: display(base.displayLarge, colors.textPrimary),
      displayMedium: display(base.displayMedium, colors.textPrimary),
      displaySmall: display(base.displaySmall, colors.textPrimary),
      headlineLarge: display(base.headlineLarge, colors.textPrimary),
      headlineMedium: display(base.headlineMedium, colors.textPrimary),
      headlineSmall: display(base.headlineSmall, colors.textPrimary),
      titleLarge: body(base.titleLarge, colors.textPrimary),
      titleMedium: body(base.titleMedium, colors.textPrimary),
      titleSmall: body(base.titleSmall, colors.textPrimary),
      bodyLarge: body(base.bodyLarge, colors.textPrimary),
      bodyMedium: body(base.bodyMedium, colors.textPrimary),
      bodySmall: body(base.bodySmall, colors.textMuted),
      labelLarge: body(base.labelLarge, colors.textPrimary),
      labelMedium: body(base.labelMedium, colors.textMuted),
      labelSmall: body(base.labelSmall, colors.textMuted),
    );
  }
}
