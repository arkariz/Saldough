/// Saklar tingkat build untuk fitur Catat dari notifikasi (ADR-032).
///
/// Fitur ini **dinonaktifkan sementara** (keputusan pemilik 24 Okt 2026):
/// tanpa `--dart-define=NOTIFICATION_CAPTURE=true` build tidak menampilkan
/// pintu apa pun (Akun, Beranda, onboarding), tidak memproses notifikasi, dan
/// mematikan layanan native. Kode, setelan, pola, dan data pengguna tetap
/// utuh, jadi menyalakannya lagi cukup dengan mengubah [compiledIn].
abstract final class NotificationCaptureAvailability {
  /// Apakah build ini menyertakan fitur. Bawaan mati; nyalakan dengan
  /// `--dart-define=NOTIFICATION_CAPTURE=true`.
  static const compiledIn = bool.fromEnvironment('NOTIFICATION_CAPTURE');

  /// Apakah pintu fitur (Akun, onboarding) boleh tampil. Bawaan `true` supaya
  /// uji widget yang tidak lewat `RootModule` tidak berubah; `RootModule`
  /// menyetelnya ke [compiledIn] saat aplikasi mulai.
  static bool visible = true;
}
