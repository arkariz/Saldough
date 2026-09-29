import 'package:dependencies/dependencies.dart';

/// Cara pengguna masuk (ADR-024). Menentukan cara re-autentikasi saat
/// operasi sensitif seperti hapus akun.
enum SignInMethod {
  /// Google Sign-In.
  google,

  /// Email dan sandi — khusus akun peninjau Play (ADR-023).
  password,
}

/// Identitas pengguna yang masuk (ADR-023). Akun sepenuhnya opsional —
/// tidak ada layar pencatatan inti yang membutuhkan ini untuk berfungsi
/// (ADR-024 §3.1).
final class AppUser extends Equatable {
  /// Membuat [AppUser].
  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.method,
  });

  /// Pengenal unik dari penyedia identitas (Firebase Auth).
  final String uid;

  /// Nama tampilan dari akun Google, kalau ada.
  final String? displayName;

  /// Alamat email akun, kalau ada.
  final String? email;

  /// URL foto profil akun Google, kalau ada.
  final String? photoUrl;

  /// Metode masuk, atau `null` kalau penyedianya tidak dikenali.
  final SignInMethod? method;

  @override
  List<Object?> get props => [uid, displayName, email, photoUrl, method];
}
