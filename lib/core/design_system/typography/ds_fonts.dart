/// Keluarga huruf design system baru (ADR-043), dibundel di `assets/fonts/`
/// dan didaftarkan di `pubspec.yaml`.
abstract final class DsFonts {
  DsFonts._();

  /// Plus Jakarta Sans (variabel): seluruh teks, judul, dan nominal biasa.
  static const String sans = 'PlusJakartaSans';

  /// Space Mono Bold: aksen piksel untuk label kapital, badge, nominal baris,
  /// angka saldo hero, label navigasi, dan logo kata.
  static const String pixel = 'SpaceMono';

  /// Cadangan bila glif tidak ada di huruf utama.
  static const List<String> fallback = ['Roboto'];
}
