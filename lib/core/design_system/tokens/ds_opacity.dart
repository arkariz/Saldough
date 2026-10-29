/// Tingkat keburaman design system baru (ADR-043).
abstract final class DsOpacity {
  DsOpacity._();

  /// Kontrol nonaktif.
  static const double disabled = 0.4;

  /// Latar kanvas tembus pandang di bawah top bar dan navigasi bawah.
  static const double chrome = 0.9;

  /// Cahaya sekitar di kartu saldo hero.
  static const double glow = 0.1;

  /// Bingkai dan isi tipis di atas kartu saldo hero.
  static const double heroHairline = 0.08;

  /// Latar tile ikon di atas kartu saldo hero.
  static const double heroTileTint = 0.2;

  /// Isi baris yang ditekan (`surfaceHover`) di dalam daftar.
  static const double rowPressed = 0.5;

  /// Catatan kaki dekoratif.
  static const double footnote = 0.6;
}
