import 'package:flutter/material.dart';
import 'package:saldough/core/theme/extensions/app_colors_extension.dart';
import 'package:saldough/core/theme/tokens/app_border.dart';
import 'package:saldough/core/theme/tokens/app_radius.dart';

/// Membungkus `child` dengan [ThemeData] bahasa visual ADR-015 — palet
/// [AppColorsExtension.pixelLight]/[AppColorsExtension.pixelDark], tiga
/// peran huruf (Space Grotesk judul/angka besar, Plus Jakarta Sans teks
/// isi/label, lihat juga [PixelTypography.tabularMono] untuk nominal
/// tabel), radius `4px`, dan garis tepi `2px` — dipasang sekali di
/// `AppShellPage`, BUKAN tema aplikasi global.
///
/// `AppTheme`/ADR-0006 tetap tema global (`MaterialApp.theme`) sampai
/// T-3.4/T-3.5 cutover — layar lama (`cycle`/`card`/`investment`/`grocery`/
/// `income`) terus memakainya tanpa perubahan apa pun. `PixelTheme` HANYA
/// berlaku untuk subtree yang dibungkusnya (layar baru Fase 2+).
///
/// Widget [Theme] bawaan Flutter otomatis diteruskan ke rute yang dibuka
/// dari dalam subtree ini (`showModalBottomSheet`, `showDialog`) lewat
/// `InheritedTheme.capture` — beda dengan `Provider`/`BlocProvider`, yang
/// TIDAK diteruskan otomatis ke rute baru (lihat catatan `Builder` di
/// `AppShellPage._openRecordSheet` untuk kasus itu). Jadi lembar CATAT dkk.
/// tetap memakai `PixelTheme` walau route-nya sendiri ditumpuk di
/// `Navigator` yang sama dengan layar lama.
class PixelTheme extends StatelessWidget {
  /// Membuat [PixelTheme] membungkus [child].
  const PixelTheme({required this.child, super.key});

  /// Subtree yang memakai tema ADR-015.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = brightness == Brightness.dark ? AppColorsExtension.pixelDark : AppColorsExtension.pixelLight;
    return Theme(data: _build(colors, brightness), child: child);
  }

  static ThemeData _build(AppColorsExtension colors, Brightness brightness) {
    final base = brightness == Brightness.light ? ThemeData.light() : ThemeData.dark();
    final colorScheme = (brightness == Brightness.light ? const ColorScheme.light() : const ColorScheme.dark()).copyWith(
      brightness: brightness,
      surface: colors.cardBackground,
      onSurface: colors.textPrimary,
      primary: colors.accent,
      onPrimary: colors.onAccent,
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
      // `showModalBottomSheet` mengambil warna dari sini, bukan dari
      // `colorScheme.surface` -- tanpa ini lembar CATAT dkk. terlihat putih
      // polos (warna kartu), bukan krem hangat `colors.background` yang
      // dimaksud ADR-015.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.background,
        modalBackgroundColor: colors.background,
      ),
      // AppHardCard adalah cara utama menampilkan kartu ADR-015 (bayangan
      // keras offset, bukan elevasi Material) -- cardTheme di sini hanya
      // jaring pengaman untuk widget Material bawaan (`Card`) kalau
      // terpakai tidak sengaja di subtree ini.
      cardTheme: CardThemeData(
        color: colors.cardBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.pixelSmAll,
          side: BorderSide(color: colors.textPrimary, width: AppBorder.pixelThick),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ).copyWith(color: colors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.pixelSmAll,
            side: BorderSide(color: colors.textPrimary, width: AppBorder.pixelThick),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.divider, thickness: 1, space: 1),
      extensions: [colors],
    );
  }

  // Dibangun slot per slot, bukan `GoogleFonts.xxxTextTheme(base)` berantai
  // -- alasan sama seperti `AppTheme._buildTextTheme` ADR-0006: helper itu
  // menimpa seluruh slot termasuk yang sudah diisi huruf lain.
  static TextTheme _buildTextTheme(TextTheme base, AppColorsExtension colors) {
    TextStyle? display(TextStyle? base, Color color) =>
        base?.copyWith(fontFamily: 'SpaceGrotesk', color: color, fontWeight: FontWeight.w700);
    TextStyle? body(TextStyle? base, Color color) => base?.copyWith(fontFamily: 'PlusJakartaSans', color: color);

    return base.copyWith(
      displayLarge: display(base.displayLarge, colors.textPrimary),
      displayMedium: display(base.displayMedium, colors.textPrimary),
      displaySmall: display(base.displaySmall, colors.textPrimary),
      headlineLarge: display(base.headlineLarge, colors.textPrimary),
      headlineMedium: display(base.headlineMedium, colors.textPrimary),
      headlineSmall: display(base.headlineSmall, colors.textPrimary),
      titleLarge: display(base.titleLarge, colors.textPrimary),
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

/// Gaya huruf ADR-015 yang tidak punya slot [TextTheme] baku.
abstract final class PixelTypography {
  PixelTypography._();

  /// Space Mono 700, berjarak huruf — dipakai untuk nominal Rupiah di
  /// kolom/daftar (bukan saldo utama, yang tetap Space Grotesk lewat
  /// [TextTheme.headlineSmall]) dan lencana status pendek. Lihat ADR-015
  /// §Tipografi: "monospace menjaga digitnya rata".
  static TextStyle tabularMono(BuildContext context, {double fontSize = 14, Color? color}) {
    return TextStyle(
      fontFamily: 'SpaceMono',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: color ?? Theme.of(context).extension<AppColorsExtension>()?.textPrimary,
    );
  }
}
