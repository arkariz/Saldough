import 'package:flutter/material.dart';

/// Pasangan warna kategori: [color] untuk ikon/teks, [container] untuk tile.
@immutable
class DsColorPair {
  /// Membuat pasangan warna kategori.
  const DsColorPair(this.color, this.container);

  /// Interpolasi dua pasangan.
  factory DsColorPair.lerp(DsColorPair a, DsColorPair b, double t) =>
      DsColorPair(Color.lerp(a.color, b.color, t)!, Color.lerp(a.container, b.container, t)!);

  /// Warna ikon atau teks kategori.
  final Color color;

  /// Latar tile kategori.
  final Color container;

  @override
  bool operator ==(Object other) => other is DsColorPair && other.color == color && other.container == container;

  @override
  int get hashCode => Object.hash(color, container);
}

/// Sepuluh pasangan warna kategori. Hanya untuk tile ikon kategori, bukan
/// untuk status atau teks biasa.
@immutable
class DsCategoryColors {
  /// Membuat palet kategori; semua pasangan wajib diisi.
  const DsCategoryColors({
    required this.orange,
    required this.green,
    required this.blue,
    required this.purple,
    required this.teal,
    required this.rose,
    required this.amber,
    required this.indigo,
    required this.brown,
    required this.slate,
  });

  /// Interpolasi dua palet kategori.
  factory DsCategoryColors.lerp(DsCategoryColors a, DsCategoryColors b, double t) => DsCategoryColors(
    orange: DsColorPair.lerp(a.orange, b.orange, t),
    green: DsColorPair.lerp(a.green, b.green, t),
    blue: DsColorPair.lerp(a.blue, b.blue, t),
    purple: DsColorPair.lerp(a.purple, b.purple, t),
    teal: DsColorPair.lerp(a.teal, b.teal, t),
    rose: DsColorPair.lerp(a.rose, b.rose, t),
    amber: DsColorPair.lerp(a.amber, b.amber, t),
    indigo: DsColorPair.lerp(a.indigo, b.indigo, t),
    brown: DsColorPair.lerp(a.brown, b.brown, t),
    slate: DsColorPair.lerp(a.slate, b.slate, t),
  );

  /// Kategori `orange`.
  final DsColorPair orange;

  /// Kategori `green`.
  final DsColorPair green;

  /// Kategori `blue`.
  final DsColorPair blue;

  /// Kategori `purple`.
  final DsColorPair purple;

  /// Kategori `teal`.
  final DsColorPair teal;

  /// Kategori `rose`.
  final DsColorPair rose;

  /// Kategori `amber`.
  final DsColorPair amber;

  /// Kategori `indigo`.
  final DsColorPair indigo;

  /// Kategori `brown`.
  final DsColorPair brown;

  /// Kategori `slate`.
  final DsColorPair slate;

  /// Seluruh pasangan, urut tetap (dipakai uji dan pemilih warna kategori).
  List<DsColorPair> get all => [orange, green, blue, purple, teal, rose, amber, indigo, brown, slate];
}

/// Skema warna design system baru (ADR-043), satu per mode per preset.
///
/// Nama field = peran di spek Autumn Kyoto Ledger
/// (`docs/03-design/design-system-kyoto/spec-autumn-kyoto-ledger.md`) dalam
/// camelCase, ditambah peran komponen dari prosa spek dan peran keuangan
/// yang tidak ada di spek. Nilai tiap preset ada di `presets/`.
@immutable
class DsColorScheme extends ThemeExtension<DsColorScheme> {
  /// Membuat skema; seluruh peran wajib diisi supaya preset tidak bolong.
  const DsColorScheme({
    required this.surface,
    required this.surfaceDim,
    required this.surfaceBright,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.outline,
    required this.outlineVariant,
    required this.surfaceTint,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.inversePrimary,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.primaryFixed,
    required this.primaryFixedDim,
    required this.onPrimaryFixed,
    required this.onPrimaryFixedVariant,
    required this.secondaryFixed,
    required this.secondaryFixedDim,
    required this.onSecondaryFixed,
    required this.onSecondaryFixedVariant,
    required this.tertiaryFixed,
    required this.tertiaryFixedDim,
    required this.onTertiaryFixed,
    required this.onTertiaryFixedVariant,
    required this.background,
    required this.onBackground,
    required this.surfaceVariant,
    required this.surfaceCanvas,
    required this.honeyBiscuit,
    required this.warmSand,
    required this.outlineSubtle,
    required this.outlineStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.surfaceFloating,
    required this.outlineFloating,
    required this.actionPrimary,
    required this.actionPrimaryPressed,
    required this.actionPrimaryStroke,
    required this.onActionPrimary,
    required this.actionSecondary,
    required this.actionSecondaryPressed,
    required this.onActionSecondary,
    required this.secondaryContainerOutline,
    required this.focusRing,
    required this.income,
    required this.incomeContainer,
    required this.onIncomeContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.shadow,
    required this.shadowTint,
    required this.shadowAccent,
    required this.scrim,
    required this.categories,
  });

  // --- Peran spek (gaya Material 3) ---

  /// Permukaan dasar Material.
  final Color surface;

  /// Permukaan paling redup.
  final Color surfaceDim;

  /// Permukaan paling terang.
  final Color surfaceBright;

  /// Wadah terendah.
  final Color surfaceContainerLowest;

  /// Wadah cekung: baki buku besar, sumur modul, baris disorot (tier 2).
  final Color surfaceContainerLow;

  /// Kartu dan panel standar (tier 1).
  final Color surfaceContainer;

  /// Panel mengambang, popover, chip netral, keadaan ditekan tombol tersier.
  final Color surfaceContainerHigh;

  /// Wadah tertinggi.
  final Color surfaceContainerHighest;

  /// Teks Material di atas surface.
  final Color onSurface;

  /// Teks Material varian.
  final Color onSurfaceVariant;

  /// Permukaan terbalik: snackbar.
  final Color inverseSurface;

  /// Teks di atas inverseSurface.
  final Color inverseOnSurface;

  /// Garis Material.
  final Color outline;

  /// Garis Material varian.
  final Color outlineVariant;

  /// Rona permukaan Material (tidak dipakai untuk elevasi).
  final Color surfaceTint;

  /// Amber gelap untuk teks, ikon, dan tautan berwarna primer (lolos 4,5:1 di kartu).
  final Color primary;

  /// Teks di atas primary.
  final Color onPrimary;

  /// Amber biji ek (#b45309), nada utama merek.
  final Color primaryContainer;

  /// Teks di atas primaryContainer.
  final Color onPrimaryContainer;

  /// Primer di atas inverseSurface.
  final Color inversePrimary;

  /// Terakota gelap untuk teks dan ikon sekunder.
  final Color secondary;

  /// Teks di atas secondary.
  final Color onSecondary;

  /// Latar chip terakota lembut.
  final Color secondaryContainer;

  /// Teks chip terakota lembut.
  final Color onSecondaryContainer;

  /// Madu untuk indikator info dan sorotan finansial.
  final Color tertiary;

  /// Teks di atas tertiary.
  final Color onTertiary;

  /// Wadah tersier.
  final Color tertiaryContainer;

  /// Teks di atas tertiaryContainer.
  final Color onTertiaryContainer;

  /// Galat dan tindakan hapus.
  final Color error;

  /// Teks di atas error.
  final Color onError;

  /// Latar banner dan badge galat.
  final Color errorContainer;

  /// Teks di atas errorContainer.
  final Color onErrorContainer;

  /// Primer tetap (sama di kedua mode).
  final Color primaryFixed;

  /// Primer tetap redup.
  final Color primaryFixedDim;

  /// Teks di atas primaryFixed.
  final Color onPrimaryFixed;

  /// Teks varian di atas primaryFixed.
  final Color onPrimaryFixedVariant;

  /// Sekunder tetap.
  final Color secondaryFixed;

  /// Sekunder tetap redup.
  final Color secondaryFixedDim;

  /// Teks di atas secondaryFixed.
  final Color onSecondaryFixed;

  /// Teks varian di atas secondaryFixed.
  final Color onSecondaryFixedVariant;

  /// Tersier tetap.
  final Color tertiaryFixed;

  /// Tersier tetap redup.
  final Color tertiaryFixedDim;

  /// Teks di atas tertiaryFixed.
  final Color onTertiaryFixed;

  /// Teks varian di atas tertiaryFixed.
  final Color onTertiaryFixedVariant;

  /// Latar Material.
  final Color background;

  /// Teks di atas background.
  final Color onBackground;

  /// Permukaan varian Material.
  final Color surfaceVariant;

  /// Kanvas washi: latar halaman, isi kolom input (tier 0).
  final Color surfaceCanvas;

  /// Aksen biskuit madu untuk sorotan dekoratif, bukan teks.
  final Color honeyBiscuit;

  /// Pasir hangat: bingkai kartu aktif/ditekan (tier 2).
  final Color warmSand;

  /// Garis pemisah baris dan bingkai kartu (tier 1).
  final Color outlineSubtle;

  /// Bingkai kolom input, checkbox, dan radio kosong.
  final Color outlineStrong;

  /// Teks utama dan nominal.
  final Color textPrimary;

  /// Teks pendukung: metadata dan label sekunder.
  final Color textSecondary;

  /// Teks tersier: keadaan nonaktif dan tag tersier (bukan untuk teks yang wajib terbaca).
  final Color textTertiary;

  // --- Peran komponen dari prosa spek ---

  /// Laci, menu, dan dialog (tier 3).
  final Color surfaceFloating;

  /// Bingkai tier 3.
  final Color outlineFloating;

  /// Isi tombol utama.
  final Color actionPrimary;

  /// Tombol utama ditekan.
  final Color actionPrimaryPressed;

  /// Garis dasar 1px tombol utama ditekan.
  final Color actionPrimaryStroke;

  /// Teks dan ikon di atas actionPrimary.
  final Color onActionPrimary;

  /// Isi tombol sekunder dan checkbox/radio terpilih.
  final Color actionSecondary;

  /// Tombol sekunder ditekan.
  final Color actionSecondaryPressed;

  /// Teks dan ikon di atas actionSecondary.
  final Color onActionSecondary;

  /// Bingkai chip terakota lembut.
  final Color secondaryContainerOutline;

  /// Cincin fokus 2px di luar kolom input.
  final Color focusRing;

  // --- Tambahan aplikasi keuangan (tidak ada di spek) ---

  /// Nominal pemasukan dan status Aman: lumut hangat teredam.
  final Color income;

  /// Latar badge dan banner pemasukan/aman.
  final Color incomeContainer;

  /// Teks di atas incomeContainer.
  final Color onIncomeContainer;

  /// Teks perlu perhatian: Perlu dicek, Hampir habis.
  final Color warning;

  /// Latar banner dan badge perhatian.
  final Color warningContainer;

  /// Teks di atas warningContainer.
  final Color onWarningContainer;

  /// Info netral dan transfer.
  final Color info;

  /// Latar banner dan badge info.
  final Color infoContainer;

  /// Teks di atas infoContainer.
  final Color onInfoContainer;

  // --- Efek ---

  /// Warna dasar bayangan (arang kastanye).
  final Color shadow;

  /// Rona terakota bayangan tier 2.
  final Color shadowTint;

  /// Rona amber bayangan tier 3.
  final Color shadowAccent;

  /// Tirai di belakang dialog dan sheet.
  final Color scrim;

  /// Pasangan warna kategori.
  final DsCategoryColors categories;

  /// [ColorScheme] Material dari peran yang sama namanya, supaya widget
  /// bawaan Material ikut berwarna preset.
  ColorScheme toMaterial(Brightness brightness) => ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    primaryFixed: primaryFixed,
    primaryFixedDim: primaryFixedDim,
    onPrimaryFixed: onPrimaryFixed,
    onPrimaryFixedVariant: onPrimaryFixedVariant,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    secondaryFixed: secondaryFixed,
    secondaryFixedDim: secondaryFixedDim,
    onSecondaryFixed: onSecondaryFixed,
    onSecondaryFixedVariant: onSecondaryFixedVariant,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    tertiaryFixed: tertiaryFixed,
    tertiaryFixedDim: tertiaryFixedDim,
    onTertiaryFixed: onTertiaryFixed,
    onTertiaryFixedVariant: onTertiaryFixedVariant,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceDim: surfaceDim,
    surfaceBright: surfaceBright,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    shadow: shadow,
    scrim: scrim,
    inverseSurface: inverseSurface,
    inversePrimary: inversePrimary,
    surfaceTint: surfaceTint,
    onInverseSurface: inverseOnSurface,
  );

  @override
  DsColorScheme copyWith({
    Color? surface,
    Color? surfaceDim,
    Color? surfaceBright,
    Color? surfaceContainerLowest,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? inverseSurface,
    Color? inverseOnSurface,
    Color? outline,
    Color? outlineVariant,
    Color? surfaceTint,
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? inversePrimary,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? primaryFixed,
    Color? primaryFixedDim,
    Color? onPrimaryFixed,
    Color? onPrimaryFixedVariant,
    Color? secondaryFixed,
    Color? secondaryFixedDim,
    Color? onSecondaryFixed,
    Color? onSecondaryFixedVariant,
    Color? tertiaryFixed,
    Color? tertiaryFixedDim,
    Color? onTertiaryFixed,
    Color? onTertiaryFixedVariant,
    Color? background,
    Color? onBackground,
    Color? surfaceVariant,
    Color? surfaceCanvas,
    Color? honeyBiscuit,
    Color? warmSand,
    Color? outlineSubtle,
    Color? outlineStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? surfaceFloating,
    Color? outlineFloating,
    Color? actionPrimary,
    Color? actionPrimaryPressed,
    Color? actionPrimaryStroke,
    Color? onActionPrimary,
    Color? actionSecondary,
    Color? actionSecondaryPressed,
    Color? onActionSecondary,
    Color? secondaryContainerOutline,
    Color? focusRing,
    Color? income,
    Color? incomeContainer,
    Color? onIncomeContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? shadow,
    Color? shadowTint,
    Color? shadowAccent,
    Color? scrim,
    DsCategoryColors? categories,
  }) {
    return DsColorScheme(
      surface: surface ?? this.surface,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      surfaceBright: surfaceBright ?? this.surfaceBright,
      surfaceContainerLowest: surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest ?? this.surfaceContainerHighest,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      inverseOnSurface: inverseOnSurface ?? this.inverseOnSurface,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      inversePrimary: inversePrimary ?? this.inversePrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      tertiary: tertiary ?? this.tertiary,
      onTertiary: onTertiary ?? this.onTertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      primaryFixed: primaryFixed ?? this.primaryFixed,
      primaryFixedDim: primaryFixedDim ?? this.primaryFixedDim,
      onPrimaryFixed: onPrimaryFixed ?? this.onPrimaryFixed,
      onPrimaryFixedVariant: onPrimaryFixedVariant ?? this.onPrimaryFixedVariant,
      secondaryFixed: secondaryFixed ?? this.secondaryFixed,
      secondaryFixedDim: secondaryFixedDim ?? this.secondaryFixedDim,
      onSecondaryFixed: onSecondaryFixed ?? this.onSecondaryFixed,
      onSecondaryFixedVariant: onSecondaryFixedVariant ?? this.onSecondaryFixedVariant,
      tertiaryFixed: tertiaryFixed ?? this.tertiaryFixed,
      tertiaryFixedDim: tertiaryFixedDim ?? this.tertiaryFixedDim,
      onTertiaryFixed: onTertiaryFixed ?? this.onTertiaryFixed,
      onTertiaryFixedVariant: onTertiaryFixedVariant ?? this.onTertiaryFixedVariant,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceCanvas: surfaceCanvas ?? this.surfaceCanvas,
      honeyBiscuit: honeyBiscuit ?? this.honeyBiscuit,
      warmSand: warmSand ?? this.warmSand,
      outlineSubtle: outlineSubtle ?? this.outlineSubtle,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      surfaceFloating: surfaceFloating ?? this.surfaceFloating,
      outlineFloating: outlineFloating ?? this.outlineFloating,
      actionPrimary: actionPrimary ?? this.actionPrimary,
      actionPrimaryPressed: actionPrimaryPressed ?? this.actionPrimaryPressed,
      actionPrimaryStroke: actionPrimaryStroke ?? this.actionPrimaryStroke,
      onActionPrimary: onActionPrimary ?? this.onActionPrimary,
      actionSecondary: actionSecondary ?? this.actionSecondary,
      actionSecondaryPressed: actionSecondaryPressed ?? this.actionSecondaryPressed,
      onActionSecondary: onActionSecondary ?? this.onActionSecondary,
      secondaryContainerOutline: secondaryContainerOutline ?? this.secondaryContainerOutline,
      focusRing: focusRing ?? this.focusRing,
      income: income ?? this.income,
      incomeContainer: incomeContainer ?? this.incomeContainer,
      onIncomeContainer: onIncomeContainer ?? this.onIncomeContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      shadow: shadow ?? this.shadow,
      shadowTint: shadowTint ?? this.shadowTint,
      shadowAccent: shadowAccent ?? this.shadowAccent,
      scrim: scrim ?? this.scrim,
      categories: categories ?? this.categories,
    );
  }

  @override
  DsColorScheme lerp(ThemeExtension<DsColorScheme>? other, double t) {
    if (other is! DsColorScheme) return this;
    return DsColorScheme(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
      surfaceBright: Color.lerp(surfaceBright, other.surfaceBright, t)!,
      surfaceContainerLowest: Color.lerp(surfaceContainerLowest, other.surfaceContainerLowest, t)!,
      surfaceContainerLow: Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerHigh: Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      surfaceContainerHighest: Color.lerp(surfaceContainerHighest, other.surfaceContainerHighest, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant: Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      inverseSurface: Color.lerp(inverseSurface, other.inverseSurface, t)!,
      inverseOnSurface: Color.lerp(inverseOnSurface, other.inverseOnSurface, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer: Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      inversePrimary: Color.lerp(inversePrimary, other.inversePrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      secondaryContainer: Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      onSecondaryContainer: Color.lerp(onSecondaryContainer, other.onSecondaryContainer, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      onTertiary: Color.lerp(onTertiary, other.onTertiary, t)!,
      tertiaryContainer: Color.lerp(tertiaryContainer, other.tertiaryContainer, t)!,
      onTertiaryContainer: Color.lerp(onTertiaryContainer, other.onTertiaryContainer, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer: Color.lerp(onErrorContainer, other.onErrorContainer, t)!,
      primaryFixed: Color.lerp(primaryFixed, other.primaryFixed, t)!,
      primaryFixedDim: Color.lerp(primaryFixedDim, other.primaryFixedDim, t)!,
      onPrimaryFixed: Color.lerp(onPrimaryFixed, other.onPrimaryFixed, t)!,
      onPrimaryFixedVariant: Color.lerp(onPrimaryFixedVariant, other.onPrimaryFixedVariant, t)!,
      secondaryFixed: Color.lerp(secondaryFixed, other.secondaryFixed, t)!,
      secondaryFixedDim: Color.lerp(secondaryFixedDim, other.secondaryFixedDim, t)!,
      onSecondaryFixed: Color.lerp(onSecondaryFixed, other.onSecondaryFixed, t)!,
      onSecondaryFixedVariant: Color.lerp(onSecondaryFixedVariant, other.onSecondaryFixedVariant, t)!,
      tertiaryFixed: Color.lerp(tertiaryFixed, other.tertiaryFixed, t)!,
      tertiaryFixedDim: Color.lerp(tertiaryFixedDim, other.tertiaryFixedDim, t)!,
      onTertiaryFixed: Color.lerp(onTertiaryFixed, other.onTertiaryFixed, t)!,
      onTertiaryFixedVariant: Color.lerp(onTertiaryFixedVariant, other.onTertiaryFixedVariant, t)!,
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      surfaceCanvas: Color.lerp(surfaceCanvas, other.surfaceCanvas, t)!,
      honeyBiscuit: Color.lerp(honeyBiscuit, other.honeyBiscuit, t)!,
      warmSand: Color.lerp(warmSand, other.warmSand, t)!,
      outlineSubtle: Color.lerp(outlineSubtle, other.outlineSubtle, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      surfaceFloating: Color.lerp(surfaceFloating, other.surfaceFloating, t)!,
      outlineFloating: Color.lerp(outlineFloating, other.outlineFloating, t)!,
      actionPrimary: Color.lerp(actionPrimary, other.actionPrimary, t)!,
      actionPrimaryPressed: Color.lerp(actionPrimaryPressed, other.actionPrimaryPressed, t)!,
      actionPrimaryStroke: Color.lerp(actionPrimaryStroke, other.actionPrimaryStroke, t)!,
      onActionPrimary: Color.lerp(onActionPrimary, other.onActionPrimary, t)!,
      actionSecondary: Color.lerp(actionSecondary, other.actionSecondary, t)!,
      actionSecondaryPressed: Color.lerp(actionSecondaryPressed, other.actionSecondaryPressed, t)!,
      onActionSecondary: Color.lerp(onActionSecondary, other.onActionSecondary, t)!,
      secondaryContainerOutline: Color.lerp(secondaryContainerOutline, other.secondaryContainerOutline, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      income: Color.lerp(income, other.income, t)!,
      incomeContainer: Color.lerp(incomeContainer, other.incomeContainer, t)!,
      onIncomeContainer: Color.lerp(onIncomeContainer, other.onIncomeContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      shadowTint: Color.lerp(shadowTint, other.shadowTint, t)!,
      shadowAccent: Color.lerp(shadowAccent, other.shadowAccent, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      categories: DsCategoryColors.lerp(categories, other.categories, t),
    );
  }

  /// Seluruh peran warna berikut namanya (tanpa kategori), untuk uji dan
  /// dokumentasi token.
  Map<String, Color> toMap() => {
    'surface': surface,
    'surfaceDim': surfaceDim,
    'surfaceBright': surfaceBright,
    'surfaceContainerLowest': surfaceContainerLowest,
    'surfaceContainerLow': surfaceContainerLow,
    'surfaceContainer': surfaceContainer,
    'surfaceContainerHigh': surfaceContainerHigh,
    'surfaceContainerHighest': surfaceContainerHighest,
    'onSurface': onSurface,
    'onSurfaceVariant': onSurfaceVariant,
    'inverseSurface': inverseSurface,
    'inverseOnSurface': inverseOnSurface,
    'outline': outline,
    'outlineVariant': outlineVariant,
    'surfaceTint': surfaceTint,
    'primary': primary,
    'onPrimary': onPrimary,
    'primaryContainer': primaryContainer,
    'onPrimaryContainer': onPrimaryContainer,
    'inversePrimary': inversePrimary,
    'secondary': secondary,
    'onSecondary': onSecondary,
    'secondaryContainer': secondaryContainer,
    'onSecondaryContainer': onSecondaryContainer,
    'tertiary': tertiary,
    'onTertiary': onTertiary,
    'tertiaryContainer': tertiaryContainer,
    'onTertiaryContainer': onTertiaryContainer,
    'error': error,
    'onError': onError,
    'errorContainer': errorContainer,
    'onErrorContainer': onErrorContainer,
    'primaryFixed': primaryFixed,
    'primaryFixedDim': primaryFixedDim,
    'onPrimaryFixed': onPrimaryFixed,
    'onPrimaryFixedVariant': onPrimaryFixedVariant,
    'secondaryFixed': secondaryFixed,
    'secondaryFixedDim': secondaryFixedDim,
    'onSecondaryFixed': onSecondaryFixed,
    'onSecondaryFixedVariant': onSecondaryFixedVariant,
    'tertiaryFixed': tertiaryFixed,
    'tertiaryFixedDim': tertiaryFixedDim,
    'onTertiaryFixed': onTertiaryFixed,
    'onTertiaryFixedVariant': onTertiaryFixedVariant,
    'background': background,
    'onBackground': onBackground,
    'surfaceVariant': surfaceVariant,
    'surfaceCanvas': surfaceCanvas,
    'honeyBiscuit': honeyBiscuit,
    'warmSand': warmSand,
    'outlineSubtle': outlineSubtle,
    'outlineStrong': outlineStrong,
    'textPrimary': textPrimary,
    'textSecondary': textSecondary,
    'textTertiary': textTertiary,
    'surfaceFloating': surfaceFloating,
    'outlineFloating': outlineFloating,
    'actionPrimary': actionPrimary,
    'actionPrimaryPressed': actionPrimaryPressed,
    'actionPrimaryStroke': actionPrimaryStroke,
    'onActionPrimary': onActionPrimary,
    'actionSecondary': actionSecondary,
    'actionSecondaryPressed': actionSecondaryPressed,
    'onActionSecondary': onActionSecondary,
    'secondaryContainerOutline': secondaryContainerOutline,
    'focusRing': focusRing,
    'income': income,
    'incomeContainer': incomeContainer,
    'onIncomeContainer': onIncomeContainer,
    'warning': warning,
    'warningContainer': warningContainer,
    'onWarningContainer': onWarningContainer,
    'info': info,
    'infoContainer': infoContainer,
    'onInfoContainer': onInfoContainer,
    'shadow': shadow,
    'shadowTint': shadowTint,
    'shadowAccent': shadowAccent,
    'scrim': scrim,
  };
}
