part of 'account_bloc.dart';

/// Event [AccountBloc].
sealed class AccountEvent {
  /// Membuat [AccountEvent].
  const AccountEvent();
}

/// Layar Akun dibuka — baca status masuk saat ini, lalu berlangganan
/// perubahannya.
final class AccountStarted extends AccountEvent {
  /// Membuat [AccountStarted].
  const AccountStarted();
}

/// Status masuk berubah dari luar bloc ini (mis. token kedaluwarsa).
final class AccountAuthChanged extends AccountEvent {
  /// Membuat [AccountAuthChanged].
  const AccountAuthChanged(this.user);

  /// Pengguna baru, atau `null` kalau tidak lagi masuk.
  final AppUser? user;
}

/// Tombol "Masuk dengan Google" ditekan.
final class AccountGoogleSignInRequested extends AccountEvent {
  /// Membuat [AccountGoogleSignInRequested].
  const AccountGoogleSignInRequested();
}

/// Formulir email/sandi dikirim.
final class AccountEmailSignInRequested extends AccountEvent {
  /// Membuat [AccountEmailSignInRequested].
  const AccountEmailSignInRequested({required this.email, required this.password});

  /// Email yang diketik.
  final String email;

  /// Sandi yang diketik.
  final String password;
}

/// Tombol "Keluar" ditekan.
final class AccountSignOutRequested extends AccountEvent {
  /// Membuat [AccountSignOutRequested].
  const AccountSignOutRequested();
}

/// Penghapusan akun dikonfirmasi lewat dialog.
final class AccountDeletionRequested extends AccountEvent {
  /// Membuat [AccountDeletionRequested].
  const AccountDeletionRequested({this.password});

  /// Sandi untuk re-autentikasi akun email/sandi, diisi setelah
  /// [AccountState.needsPassword] meminta.
  final String? password;
}
