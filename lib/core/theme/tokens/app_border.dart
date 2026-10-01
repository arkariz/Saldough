/// Lebar garis tepi tebal khas panel komik — bukan pelengkap, melainkan
/// motif wajib (ADR-0006: "garis tepi tebal 2.5–3px" di kedua mode). Pakai
/// ini, bukan angka harfiah, di setiap `Border.all`/`BorderSide` yang
/// membentuk panel/tombol/chip komik.
///
/// Sisa ADR-0006; tema aplikasi sendiri memakai [pixelThick] (ADR-031).
abstract final class AppBorder {
  AppBorder._();

  /// Lebar baku garis tepi komik ADR-0006.
  static const double thick = 2.5;

  /// Lebar garis tepi ADR-015 ("garis tepi 2px solid" di seluruh level
  /// elevasi). Nilai berbeda dari [thick] ADR-0006 (2.5px); jangan
  /// disamakan, keduanya milik bahasa visual yang berbeda (lihat
  /// `PixelTheme`).
  static const double pixelThick = 2;
}
