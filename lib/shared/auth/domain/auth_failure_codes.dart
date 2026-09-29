import 'package:failures/failures.dart';

/// Kode galat [AuthRepository]. Lapisan data hanya memilih kode; teks untuk
/// pengguna dipilih di presentasi lewat i18n (ADR-024).
abstract final class AuthFailureCodes {
  /// Pengguna menutup dialog masuk sendiri — bukan galat sungguhan.
  static const canceled = FailureCode('AUTH_CANCELED');

  /// Tidak bisa menghubungi Google/Firebase.
  static const network = FailureCode('AUTH_NETWORK');

  /// Email atau sandi salah.
  static const wrongCredentials = FailureCode('AUTH_WRONG_CREDENTIALS');

  /// Terlalu banyak percobaan dalam waktu singkat.
  static const tooManyRequests = FailureCode('AUTH_TOO_MANY_REQUESTS');

  /// Akun dinonaktifkan di Firebase Console.
  static const userDisabled = FailureCode('AUTH_USER_DISABLED');

  /// Sesi terlalu lama untuk hapus akun; akun email/sandi perlu sandinya.
  static const passwordRequired = FailureCode('AUTH_REAUTH_PASSWORD_REQUIRED');

  /// Galat auth lain yang tidak dipetakan khusus.
  static const other = FailureCode('AUTH_OTHER');
}
