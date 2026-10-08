/// Token ukuran design system (`tokens.json` grup size). Pakai ini, bukan
/// angka harfiah, untuk sudut piksel, target sentuh, dan tinggi komponen.
abstract final class AppSize {
  AppSize._();

  /// `pixel-step`: langkah sudut tangga kartu, daftar, banner, snackbar,
  /// dialog, dan tombol Catat.
  static const double pixelStep = 4;

  /// `pixel-step-sm`: langkah sudut tangga tombol, chip, badge, tile ikon,
  /// segmen, tombol keypad, dan kolom input.
  static const double pixelStepSm = 2;

  /// `size-touch`: target sentuh minimum.
  static const double touch = 48;

  /// `size-icon`: ikon Material Symbols.
  static const double icon = 24;

  /// `size-icon-sm`: ikon kecil di chip dan badge.
  static const double iconSm = 20;

  /// `size-tile`: tile ikon kategori dan dompet.
  static const double tile = 40;

  /// Ukuran tampil ikon piksel di dalam tile (skala 1:1).
  static const double pixelIcon = 32;

  /// `size-button`: tinggi tombol standar.
  static const double button = 48;

  /// `size-button-sm`: tinggi tombol kecil.
  static const double buttonSm = 36;

  /// `size-field`: tinggi kolom input.
  static const double field = 52;

  /// `size-row`: tinggi minimum baris daftar.
  static const double row = 64;

  /// `size-topbar`: tinggi bar atas.
  static const double topbar = 64;

  /// `size-navbar`: tinggi navigasi bawah.
  static const double navbar = 72;

  /// `size-catat`: sisi tombol Catat di navigasi bawah.
  static const double catat = 56;

  /// `opacity-disabled`: kontrol nonaktif.
  static const double disabledOpacity = 0.4;
}
