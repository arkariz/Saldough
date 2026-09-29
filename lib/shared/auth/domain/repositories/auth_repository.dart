import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/auth/domain/entities/app_user.dart';

/// Kontrak identitas opsional (ADR-023). Selalu `Either<Failure, T>`, tidak
/// pernah `throw` — sama seperti repository data lain (ADR-0005).
///
/// Tidak ada metode untuk membaca/menulis dompet, transaksi, atau anggaran
/// di sini — repository ini murni identitas. Menyinkronkan data keuangan
/// adalah cakupan ADR terpisah (lihat ADR-023 §2).
abstract interface class AuthRepository {
  /// Aliran perubahan status masuk — `null` berarti belum/tidak lagi masuk.
  Stream<AppUser?> authStateChanges();

  /// Pengguna yang sedang masuk saat ini, tanpa menunggu aliran.
  AppUser? get currentUser;

  /// Memicu alur masuk Google interaktif.
  ///
  /// `Left(AuthenticationFailure)` kalau pengguna membatalkan dialognya
  /// sendiri — itu bukan galat sungguhan, tampilkan sebagai batal, bukan
  /// pesan kegagalan.
  Future<Either<Failure, AppUser>> signInWithGoogle();

  /// Masuk dengan email dan sandi.
  ///
  /// Jalur ini ada terutama supaya peninjau Google Play bisa masuk tanpa
  /// akun Google sungguhan — kalau layar consent OAuth proyek Firebase
  /// belum diverifikasi Google, ia membatasi masuk ke daftar tester
  /// eksplisit saja, dan itu sering menyulitkan peninjauan. Akun email
  /// tester dibuat manual di Firebase Console (Authentication → Users →
  /// Add user), BUKAN lewat pendaftaran mandiri di aplikasi — tidak ada
  /// jalur "daftar" yang sengaja dibuka di sini.
  Future<Either<Failure, AppUser>> signInWithEmailAndPassword({required String email, required String password});

  /// Keluar dari akun yang sedang masuk. Tidak berefek kalau belum masuk.
  Future<Either<Failure, Unit>> signOut();

  /// Menghapus akun secara permanen dari penyedia identitas.
  ///
  /// ⚠ Ini menghapus identitas Firebase, BUKAN dompet/transaksi/anggaran di
  /// perangkat — data lokal milik perangkat, bukan akun (ADR-024 §3.2).
  ///
  /// Kalau sesi terlalu lama (`requires-recent-login`), akun Google
  /// di-re-autentikasi lewat Google sekali secara internal; akun email/sandi
  /// memakai [password], dan tanpa [password] mengembalikan
  /// `Left` berkode `AuthFailureCodes.passwordRequired` supaya UI memintanya.
  Future<Either<Failure, Unit>> deleteAccount({String? password});
}
