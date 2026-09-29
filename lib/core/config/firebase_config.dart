/// Nilai konfigurasi Firebase yang tidak ada di `google-services.json`
/// (ADR-023) — satu-satunya tempat pemilik perlu menyunting sebelum Google
/// Sign-In bisa mengeluarkan `idToken` yang valid untuk Firebase Auth di
/// Android.
abstract final class FirebaseConfig {
  FirebaseConfig._();

  /// OAuth **Web client ID** (bukan client ID Android) dari proyek
  /// Firebase yang sama dengan `android/app/google-services.json`.
  ///
  /// Cara mendapatkannya: Firebase Console → Project settings → General →
  /// scroll ke app Web (buat satu kalau belum ada, tidak perlu dipakai
  /// sungguhan) → App ID/Web client ID. Atau: buka
  /// `google-services.json`, cari entri `oauth_client` dengan
  /// `"client_type": 3` — nilai `client_id`-nya itu yang dipakai di sini.
  ///
  /// Tanpa ini, `GoogleSignIn.authenticate()` di Android tetap bisa
  /// menampilkan dialog pilih akun, tapi `idToken`-nya bisa `null` atau
  /// audiensnya tidak cocok, dan `signInWithCredential` di Firebase akan
  /// gagal. Lihat README google_sign_in v7 dan dokumentasi FlutterFire
  /// "Configure Google Sign-In" untuk detail per platform.
  static const String? googleServerClientId = null;
}
