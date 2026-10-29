/// Keluarga huruf design system baru (ADR-043), dibundel di `assets/fonts/`
/// dan didaftarkan di `pubspec.yaml`. Ketiganya berkas variabel.
abstract final class DsFonts {
  DsFonts._();

  /// Epilogue: judul, kepala modal, pemisah informasi.
  static const String heading = 'Epilogue';

  /// Source Sans 3: teks isi.
  static const String body = 'SourceSans3';

  /// JetBrains Mono: angka, nominal, jam, label teknis.
  static const String mono = 'JetBrainsMono';

  /// Cadangan bila glif tidak ada di huruf utama.
  static const List<String> fallback = ['Roboto'];
}
