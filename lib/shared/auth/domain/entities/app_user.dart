import 'package:dependencies/dependencies.dart';

/// Identitas pengguna yang masuk (ADR-023). Akun sepenuhnya opsional —
/// tidak ada layar pencatatan inti yang membutuhkan ini untuk berfungsi
/// (aturan #8 CLAUDE.md tetap berlaku: CATAT bukan bagian dari alur akun).
final class AppUser extends Equatable {
  /// Membuat [AppUser].
  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  /// Pengenal unik dari penyedia identitas (Firebase Auth).
  final String uid;

  /// Nama tampilan dari akun Google, kalau ada.
  final String? displayName;

  /// Alamat email akun Google, kalau ada.
  final String? email;

  /// URL foto profil akun Google, kalau ada.
  final String? photoUrl;

  @override
  List<Object?> get props => [uid, displayName, email, photoUrl];
}
