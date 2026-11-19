/// Jejak langkah startup: langkah terakhir yang dimulai dan apakah layar
/// pertama sudah tampil. Dibaca penjaga startup (`main`) saat startup
/// tertahan atau gagal, supaya pesannya menyebut langkah yang bermasalah.
///
/// Sengaja sederhana (string statis): berjalan sebelum DI, i18n, dan Firebase
/// siap, jadi tidak boleh bergantung pada satu pun dari itu.
abstract final class BootTrace {
  BootTrace._();

  static String _step = 'main';
  static bool _shown = false;
  static final List<String> _history = [];

  /// Langkah terakhir yang dimulai.
  static String get step => _step;

  /// Runut langkah yang sudah dimulai, terlama dulu (paling banyak 40).
  static List<String> get history => List.unmodifiable(_history);

  /// Layar pertama aplikasi sudah dirender (`runApp` sudah dipanggil).
  static bool get shown => _shown;

  /// Menandai [step] dimulai.
  static void mark(String step) {
    _step = step;
    _history.add(step);
    if (_history.length > 40) _history.removeAt(0);
  }

  /// Menandai layar pertama sudah tampil; penjaga berhenti.
  static void markShown() => _shown = true;

  /// Untuk uji.
  static void reset() {
    _step = 'main';
    _shown = false;
    _history.clear();
  }
}
