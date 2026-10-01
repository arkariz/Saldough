import 'package:flutter/material.dart';
import 'package:saldough/core/theme/extensions/app_colors_extension.dart';
import 'package:saldough/core/theme/tokens/app_border.dart';
import 'package:saldough/core/theme/tokens/app_radius.dart';

/// Tema global aplikasi ([ADR-031](docs/02-architecture/adr/0031-pixeltheme-jadi-tema-global.md)):
/// [ThemeData] bahasa visual ADR-015 — palet
/// [AppColorsExtension.pixelLight]/[AppColorsExtension.pixelDark], tiga
/// peran huruf bundel (Space Grotesk judul/angka besar, Plus Jakarta Sans
/// teks isi/label, lihat juga [PixelTypography.tabularMono] untuk nominal
/// tabel), radius `4px`, dan garis tepi `2px`.
///
/// Dipasang sekali sebagai `theme`/`darkTheme` `MaterialApp`; layar dan rute
/// tidak membungkus dirinya sendiri dengan tema.
abstract final class PixelTheme {
  PixelTheme._();

  /// Tema mode terang.
  static ThemeData get light => _build(AppColorsExtension.pixelLight, Brightness.light);

  /// Tema mode gelap (arang hangat, ADR-016 §7).
  static ThemeData get dark => _build(AppColorsExtension.pixelDark, Brightness.dark);

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
          side: BorderSide(color: colors.edge, width: AppBorder.pixelThick),
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
            side: BorderSide(color: colors.edge, width: AppBorder.pixelThick),
          ),
        ),
      ),
      // Bilah bawah ADR-015: latar hangat sedikit di atas `background`, TANPA
      // pil indikator Material (bawaannya teal, tidak ada di palet) -- tab
      // aktif dibedakan lewat warna label saja, seperti rujukan visual.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Color.alphaBlend(colors.textPrimary.withValues(alpha: 0.025), colors.background),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'SpaceMono',
            // Minimum 11px (ADR-020 §3.2) -- sebelumnya 10px.
            fontSize: kMinLabelSize,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected) ? colors.accent : colors.textMuted,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.divider, thickness: 1, space: 1),
      // Dialog dan pemilih tanggal: permukaan hangat `background`, sudut
      // `pixelSm`, dan garis tepi -- tanpa ini keduanya memakai bentuk bulat
      // besar Material dan, di mode gelap, hitam dingin bawaan (B-18).
      dialogTheme: DialogThemeData(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: _panelShape(colors),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        headerForegroundColor: colors.textPrimary,
        elevation: 0,
        shape: _panelShape(colors),
        dividerColor: colors.divider,
      ),
      extensions: [colors],
    );
  }

  static ShapeBorder _panelShape(AppColorsExtension colors) => RoundedRectangleBorder(
    borderRadius: AppRadius.pixelSmAll,
    side: BorderSide(color: colors.edge, width: AppBorder.pixelThick),
  );

  // Dibangun slot per slot supaya tiap peran huruf hanya mengisi slotnya
  // sendiri, tidak menimpa slot yang sudah diisi huruf lain.
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

/// Ukuran minimum label mikro (ADR-020 §3.2) -- tidak ada label lebih kecil
/// dari ini di seluruh aplikasi.
const double kMinLabelSize = 11;

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
