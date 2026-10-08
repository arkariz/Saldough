import 'package:flutter/material.dart';

/// Token warna Tanukonomy ([ADR-034](docs/02-architecture/adr/0034-bahasa-visual-buku-catatan-piksel.md)),
/// dipasang lewat [ThemeData.extensions].
///
/// Nama dan nilai persis `tokens.json` design system (`docs/03-design/
/// design-system/`), dalam camelCase: `surface-2` jadi [surface2]. Jangan
/// menulis warna harfiah di widget, selalu lewat `context.appColors`.
///
/// Peran singkat (README design system bagian Warna): latar `bg`, kartu
/// `surface`, kontrol cekung `surface2`; teks `ink`/`ink2`/`ink3`; tindakan
/// `brand`; status `positive`/`warning`/`danger` selalu bersama teks.
/// Pengeluaran `ink`, pemasukan `positive`, transfer `ink2`. Warna kategori
/// `cat*` hanya untuk tile ikon.
class AppColors extends ThemeExtension<AppColors> {
  /// Membuat [AppColors] dengan seluruh token wajib diisi.
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.surfaceRaised,
    required this.line,
    required this.lineStrong,
    required this.track,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.brand,
    required this.brandPressed,
    required this.brandDeep,
    required this.onBrand,
    required this.brandSoft,
    required this.brandInk,
    required this.straw,
    required this.positive,
    required this.positiveSoft,
    required this.danger,
    required this.dangerSoft,
    required this.warning,
    required this.warningSoft,
    required this.warningFill,
    required this.info,
    required this.infoSoft,
    required this.inverseSurface,
    required this.onInverse,
    required this.inverseBrand,
    required this.focus,
    required this.scrim,
    required this.catOrangeBg,
    required this.catOrange,
    required this.catGreenBg,
    required this.catGreen,
    required this.catBlueBg,
    required this.catBlue,
    required this.catPurpleBg,
    required this.catPurple,
    required this.catTealBg,
    required this.catTeal,
    required this.catRoseBg,
    required this.catRose,
    required this.catAmberBg,
    required this.catAmber,
    required this.catIndigoBg,
    required this.catIndigo,
    required this.catBrownBg,
    required this.catBrown,
    required this.catSlateBg,
    required this.catSlate,
  });

  /// `bg`: Latar halaman di bawah kartu. Jangan dipakai untuk kartu.
  final Color bg;

  /// `surface`: Kartu, sheet, dialog, bar navigasi bawah.
  final Color surface;

  /// `surface-2`: Permukaan cekung di dalam surface: track kontrol segmen, kolom pencarian, tombol sekunder, chip, tombol keypad.
  final Color surface2;

  /// `surface-3`: Keadaan ditekan untuk baris, chip, dan tombol sekunder.
  final Color surface3;

  /// `surface-raised`: Bagian yang menonjol di atas surface-2: segmen terpilih di kontrol segmen.
  final Color surfaceRaised;

  /// `line`: Garis pemisah antarbaris di dalam kartu. Dekoratif, tidak membawa makna.
  final Color line;

  /// `line-strong`: Garis tepi kolom input dan switch mati. Minimal 3:1 di surface dan surface-2.
  final Color lineStrong;

  /// `track`: Jalur kosong progress bar.
  final Color track;

  /// `ink`: Teks utama dan nominal di bg, surface, surface-2, dan brand-soft. Juga isi progress bar yang aman.
  final Color ink;

  /// `ink-2`: Teks pendukung di bg, surface, surface-2: subjudul baris, label kolom, keterangan.
  final Color ink2;

  /// `ink-3`: Teks tersier di bg, surface, surface-2: placeholder, jam, sumber. Tetap 4,5:1.
  final Color ink3;

  /// `brand`: Terakota dari ikon aplikasi. Tombol utama, tombol Catat, tautan teks. Satu tombol brand per layar.
  final Color brand;

  /// `brand-pressed`: Keadaan ditekan tombol brand.
  final Color brandPressed;

  /// `brand-deep`: Bayangan piksel keras di bawah tombol Catat dan tombol utama.
  final Color brandDeep;

  /// `on-brand`: Teks dan ikon di atas brand dan brand-pressed.
  final Color onBrand;

  /// `brand-soft`: Latar pilihan aktif: chip terpilih, indikator tab aktif di navigasi bawah.
  final Color brandSoft;

  /// `brand-ink`: Teks dan ikon di atas brand-soft.
  final Color brandInk;

  /// `straw`: Kuning topi tanuki. Hanya untuk aksen dekoratif dan ilustrasi, tidak pernah untuk teks.
  final Color straw;

  /// `positive`: Nominal pemasukan (+), status Diterima dan Aman, di bg, surface, dan positive-soft.
  final Color positive;

  /// `positive-soft`: Latar badge dan banner positif.
  final Color positiveSoft;

  /// `danger`: Lewat anggaran, galat, tindakan hapus. Selalu bersama teks atau ikon.
  final Color danger;

  /// `danger-soft`: Latar badge dan banner bahaya.
  final Color dangerSoft;

  /// `warning`: Teks yang perlu perhatian: Perlu dicek, Tertunda, Hampir habis. Di bg, surface, warning-soft.
  final Color warning;

  /// `warning-soft`: Latar banner dan badge perhatian.
  final Color warningSoft;

  /// `warning-fill`: Isi progress bar yang sudah 85% atau lebih.
  final Color warningFill;

  /// `info`: Transfer antardompet dan info netral, di surface dan info-soft.
  final Color info;

  /// `info-soft`: Latar badge dan banner info, tile ikon transfer.
  final Color infoSoft;

  /// `inverse-surface`: Latar snackbar.
  final Color inverseSurface;

  /// `on-inverse`: Teks di inverse-surface.
  final Color onInverse;

  /// `inverse-brand`: Tombol aksi teks di snackbar (Urungkan).
  final Color inverseBrand;

  /// `focus`: Cincin fokus keyboard 2px dengan jarak 2px. Minimal 3:1 di semua permukaan.
  final Color focus;

  /// `scrim`: Latar gelap di belakang sheet dan dialog.
  final Color scrim;

  /// `cat-orange-bg`: Tile kategori Makan & Minum.
  final Color catOrangeBg;

  /// `cat-orange`: Ikon di cat-orange-bg.
  final Color catOrange;

  /// `cat-green-bg`: Tile kategori Belanja Harian, Gaji; dompet Tunai.
  final Color catGreenBg;

  /// `cat-green`: Ikon di cat-green-bg.
  final Color catGreen;

  /// `cat-blue-bg`: Tile kategori Transportasi; dompet Bank.
  final Color catBlueBg;

  /// `cat-blue`: Ikon di cat-blue-bg.
  final Color catBlue;

  /// `cat-purple-bg`: Tile kategori Tagihan.
  final Color catPurpleBg;

  /// `cat-purple`: Ikon di cat-purple-bg.
  final Color catPurple;

  /// `cat-teal-bg`: Tile kategori Pulsa & Internet; dompet digital.
  final Color catTealBg;

  /// `cat-teal`: Ikon di cat-teal-bg.
  final Color catTeal;

  /// `cat-rose-bg`: Tile kategori Kesehatan, Hadiah.
  final Color catRoseBg;

  /// `cat-rose`: Ikon di cat-rose-bg.
  final Color catRose;

  /// `cat-amber-bg`: Tile kategori Belanja, Bonus; dompet Tabungan.
  final Color catAmberBg;

  /// `cat-amber`: Ikon di cat-amber-bg.
  final Color catAmber;

  /// `cat-indigo-bg`: Tile kategori Pendidikan, Hiburan, Freelance.
  final Color catIndigoBg;

  /// `cat-indigo`: Ikon di cat-indigo-bg.
  final Color catIndigo;

  /// `cat-brown-bg`: Tile kategori Keluarga, Donasi; dompet Kartu.
  final Color catBrownBg;

  /// `cat-brown`: Ikon di cat-brown-bg.
  final Color catBrown;

  /// `cat-slate-bg`: Tile kategori Lainnya dan Tanpa kategori.
  final Color catSlateBg;

  /// `cat-slate`: Ikon di cat-slate-bg.
  final Color catSlate;

  /// Token mode terang (`PixelTheme.light`).
  static const AppColors light = AppColors(
    bg: Color(0xFFF7F5F2),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF0ECE8),
    surface3: Color(0xFFE7E1DB),
    surfaceRaised: Color(0xFFFFFFFF),
    line: Color(0xFFE8E2DC),
    lineStrong: Color(0xFF8C8178),
    track: Color(0xFFEAE4DE),
    ink: Color(0xFF2A1F18),
    ink2: Color(0xFF62564D),
    ink3: Color(0xFF716559),
    brand: Color(0xFFA94F33),
    brandPressed: Color(0xFF8F412A),
    brandDeep: Color(0xFF7D3A25),
    onBrand: Color(0xFFFFFFFF),
    brandSoft: Color(0xFFF8E8E1),
    brandInk: Color(0xFF8E3F27),
    straw: Color(0xFFE9B451),
    positive: Color(0xFF1E7548),
    positiveSoft: Color(0xFFE3F1E8),
    danger: Color(0xFFB3263A),
    dangerSoft: Color(0xFFFBE7E9),
    warning: Color(0xFF875800),
    warningSoft: Color(0xFFFBF0D8),
    warningFill: Color(0xFFA06C0E),
    info: Color(0xFF2F5D8A),
    infoSoft: Color(0xFFE4EDF6),
    inverseSurface: Color(0xFF2A1F18),
    onInverse: Color(0xFFF5EFE9),
    inverseBrand: Color(0xFFF4A584),
    focus: Color(0xFF1F6FB2),
    scrim: Color(0x7A14100D),
    catOrangeBg: Color(0xFFFCEBDF),
    catOrange: Color(0xFFA4471A),
    catGreenBg: Color(0xFFE2F1E3),
    catGreen: Color(0xFF2C6E36),
    catBlueBg: Color(0xFFE3ECF8),
    catBlue: Color(0xFF2A5C9E),
    catPurpleBg: Color(0xFFEEE8F7),
    catPurple: Color(0xFF62439E),
    catTealBg: Color(0xFFDDF1EF),
    catTeal: Color(0xFF156B66),
    catRoseBg: Color(0xFFFBE6EC),
    catRose: Color(0xFFA33556),
    catAmberBg: Color(0xFFFAEFD6),
    catAmber: Color(0xFF80590A),
    catIndigoBg: Color(0xFFE6E8F8),
    catIndigo: Color(0xFF3D47A0),
    catBrownBg: Color(0xFFF1E7DE),
    catBrown: Color(0xFF704A30),
    catSlateBg: Color(0xFFECEAE7),
    catSlate: Color(0xFF5C5752),
  );

  /// Token mode gelap (`PixelTheme.dark`).
  static const AppColors dark = AppColors(
    bg: Color(0xFF14100D),
    surface: Color(0xFF1E1915),
    surface2: Color(0xFF2A231E),
    surface3: Color(0xFF362E28),
    surfaceRaised: Color(0xFF3A322B),
    line: Color(0xFF342C26),
    lineStrong: Color(0xFF857A71),
    track: Color(0xFF342C26),
    ink: Color(0xFFF5EFE9),
    ink2: Color(0xFFCDC2B8),
    ink3: Color(0xFFA79A8F),
    brand: Color(0xFFEE8A63),
    brandPressed: Color(0xFFF4A07F),
    brandDeep: Color(0xFFB05A39),
    onBrand: Color(0xFF2A1208),
    brandSoft: Color(0xFF3D241A),
    brandInk: Color(0xFFF4A584),
    straw: Color(0xFFE9B451),
    positive: Color(0xFF6FCB97),
    positiveSoft: Color(0xFF16301F),
    danger: Color(0xFFF48C95),
    dangerSoft: Color(0xFF3D1D21),
    warning: Color(0xFFEDB95A),
    warningSoft: Color(0xFF362A12),
    warningFill: Color(0xFFD9A23C),
    info: Color(0xFF93BCEB),
    infoSoft: Color(0xFF1A2735),
    inverseSurface: Color(0xFFF5EFE9),
    onInverse: Color(0xFF2A1F18),
    inverseBrand: Color(0xFFA94F33),
    focus: Color(0xFF8CC2F5),
    scrim: Color(0xA3000000),
    catOrangeBg: Color(0xFF3A2416),
    catOrange: Color(0xFFF3A675),
    catGreenBg: Color(0xFF18301B),
    catGreen: Color(0xFF86CF8F),
    catBlueBg: Color(0xFF172638),
    catBlue: Color(0xFF8FB7EC),
    catPurpleBg: Color(0xFF271F38),
    catPurple: Color(0xFFBBA2EA),
    catTealBg: Color(0xFF122E2C),
    catTeal: Color(0xFF7FD0C8),
    catRoseBg: Color(0xFF371A23),
    catRose: Color(0xFFF29AB4),
    catAmberBg: Color(0xFF33280F),
    catAmber: Color(0xFFE9C26A),
    catIndigoBg: Color(0xFF1D2038),
    catIndigo: Color(0xFFA7AEF0),
    catBrownBg: Color(0xFF2E2219),
    catBrown: Color(0xFFD6AE8D),
    catSlateBg: Color(0xFF272421),
    catSlate: Color(0xFFC4BDB6),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? surfaceRaised,
    Color? line,
    Color? lineStrong,
    Color? track,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? brand,
    Color? brandPressed,
    Color? brandDeep,
    Color? onBrand,
    Color? brandSoft,
    Color? brandInk,
    Color? straw,
    Color? positive,
    Color? positiveSoft,
    Color? danger,
    Color? dangerSoft,
    Color? warning,
    Color? warningSoft,
    Color? warningFill,
    Color? info,
    Color? infoSoft,
    Color? inverseSurface,
    Color? onInverse,
    Color? inverseBrand,
    Color? focus,
    Color? scrim,
    Color? catOrangeBg,
    Color? catOrange,
    Color? catGreenBg,
    Color? catGreen,
    Color? catBlueBg,
    Color? catBlue,
    Color? catPurpleBg,
    Color? catPurple,
    Color? catTealBg,
    Color? catTeal,
    Color? catRoseBg,
    Color? catRose,
    Color? catAmberBg,
    Color? catAmber,
    Color? catIndigoBg,
    Color? catIndigo,
    Color? catBrownBg,
    Color? catBrown,
    Color? catSlateBg,
    Color? catSlate,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      track: track ?? this.track,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      brand: brand ?? this.brand,
      brandPressed: brandPressed ?? this.brandPressed,
      brandDeep: brandDeep ?? this.brandDeep,
      onBrand: onBrand ?? this.onBrand,
      brandSoft: brandSoft ?? this.brandSoft,
      brandInk: brandInk ?? this.brandInk,
      straw: straw ?? this.straw,
      positive: positive ?? this.positive,
      positiveSoft: positiveSoft ?? this.positiveSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      warningFill: warningFill ?? this.warningFill,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      onInverse: onInverse ?? this.onInverse,
      inverseBrand: inverseBrand ?? this.inverseBrand,
      focus: focus ?? this.focus,
      scrim: scrim ?? this.scrim,
      catOrangeBg: catOrangeBg ?? this.catOrangeBg,
      catOrange: catOrange ?? this.catOrange,
      catGreenBg: catGreenBg ?? this.catGreenBg,
      catGreen: catGreen ?? this.catGreen,
      catBlueBg: catBlueBg ?? this.catBlueBg,
      catBlue: catBlue ?? this.catBlue,
      catPurpleBg: catPurpleBg ?? this.catPurpleBg,
      catPurple: catPurple ?? this.catPurple,
      catTealBg: catTealBg ?? this.catTealBg,
      catTeal: catTeal ?? this.catTeal,
      catRoseBg: catRoseBg ?? this.catRoseBg,
      catRose: catRose ?? this.catRose,
      catAmberBg: catAmberBg ?? this.catAmberBg,
      catAmber: catAmber ?? this.catAmber,
      catIndigoBg: catIndigoBg ?? this.catIndigoBg,
      catIndigo: catIndigo ?? this.catIndigo,
      catBrownBg: catBrownBg ?? this.catBrownBg,
      catBrown: catBrown ?? this.catBrown,
      catSlateBg: catSlateBg ?? this.catSlateBg,
      catSlate: catSlate ?? this.catSlate,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      track: Color.lerp(track, other.track, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandPressed: Color.lerp(brandPressed, other.brandPressed, t)!,
      brandDeep: Color.lerp(brandDeep, other.brandDeep, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      brandInk: Color.lerp(brandInk, other.brandInk, t)!,
      straw: Color.lerp(straw, other.straw, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      positiveSoft: Color.lerp(positiveSoft, other.positiveSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      warningFill: Color.lerp(warningFill, other.warningFill, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      inverseSurface: Color.lerp(inverseSurface, other.inverseSurface, t)!,
      onInverse: Color.lerp(onInverse, other.onInverse, t)!,
      inverseBrand: Color.lerp(inverseBrand, other.inverseBrand, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      catOrangeBg: Color.lerp(catOrangeBg, other.catOrangeBg, t)!,
      catOrange: Color.lerp(catOrange, other.catOrange, t)!,
      catGreenBg: Color.lerp(catGreenBg, other.catGreenBg, t)!,
      catGreen: Color.lerp(catGreen, other.catGreen, t)!,
      catBlueBg: Color.lerp(catBlueBg, other.catBlueBg, t)!,
      catBlue: Color.lerp(catBlue, other.catBlue, t)!,
      catPurpleBg: Color.lerp(catPurpleBg, other.catPurpleBg, t)!,
      catPurple: Color.lerp(catPurple, other.catPurple, t)!,
      catTealBg: Color.lerp(catTealBg, other.catTealBg, t)!,
      catTeal: Color.lerp(catTeal, other.catTeal, t)!,
      catRoseBg: Color.lerp(catRoseBg, other.catRoseBg, t)!,
      catRose: Color.lerp(catRose, other.catRose, t)!,
      catAmberBg: Color.lerp(catAmberBg, other.catAmberBg, t)!,
      catAmber: Color.lerp(catAmber, other.catAmber, t)!,
      catIndigoBg: Color.lerp(catIndigoBg, other.catIndigoBg, t)!,
      catIndigo: Color.lerp(catIndigo, other.catIndigo, t)!,
      catBrownBg: Color.lerp(catBrownBg, other.catBrownBg, t)!,
      catBrown: Color.lerp(catBrown, other.catBrown, t)!,
      catSlateBg: Color.lerp(catSlateBg, other.catSlateBg, t)!,
      catSlate: Color.lerp(catSlate, other.catSlate, t)!,
    );
  }
}

/// Akses singkat ke [AppColors] dari [BuildContext].
///
/// Jatuh ke [AppColors.light] kalau ekstensi belum terpasang (mis. uji widget
/// tanpa tema), sehingga tidak pernah melempar.
extension AppColorsContext on BuildContext {
  /// Token warna tema aktif.
  AppColors get appColors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
}

/// Pembantu peralihan Fase 14: latar pucat berwarna yang dipakai layar lama.
/// Layar yang sudah memakai komponen baru (T-14.3 dst.) memakai token `*Soft`
/// atau `cat*Bg` langsung; hapus ekstensi ini begitu tidak ada pemakainya.
extension AppColorsTints on AppColors {
  /// [fill] dilarutkan ke [surface] sebesar [strength] (0..1).
  Color tinted(Color fill, double strength) => Color.alphaBlend(fill.withValues(alpha: strength), surface);

  /// Latar tile ikon. Ikon piksel selalu di tile netral [surface2]
  /// (design system bagian Ikon); [fill] diabaikan.
  Color iconTile(Color? fill) => surface2;
}
