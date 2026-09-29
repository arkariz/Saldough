import 'package:saldough/shared/auth/auth.dart';
import 'package:state_management/state_management.dart';

/// Aksi layar Akun yang bisa sedang berjalan — tombolnya menampilkan
/// indikator memuat, tombol lain dinonaktifkan.
enum AccountAction {
  /// Masuk dengan Google.
  googleSignIn,

  /// Masuk dengan email/sandi.
  emailSignIn,

  /// Keluar.
  signOut,

  /// Hapus akun.
  delete,
}

/// Status layar Akun (ADR-023, ADR-024).
final class AccountState extends UiState<AccountState> {
  /// Membuat [AccountState].
  const AccountState({required this.user, this.pending, this.needsPassword = false, super.effect});

  /// State awal, sebelum status masuk diketahui.
  factory AccountState.initial() => const AccountState(user: null);

  /// Pengguna yang sedang masuk, atau `null` kalau belum/tidak lagi masuk.
  final AppUser? user;

  /// Aksi yang sedang berjalan, atau `null` kalau tidak ada.
  final AccountAction? pending;

  /// Hapus akun email/sandi butuh sandi karena sesinya sudah lama — layar
  /// meminta sandi lalu mengirim ulang permintaan hapus.
  final bool needsPassword;

  /// Ada aksi yang sedang berjalan.
  bool get isBusy => pending != null;

  @override
  AccountState copyWith({
    AppUser? Function()? user,
    AccountAction? Function()? pending,
    bool? needsPassword,
    UiEffect? effect,
  }) => AccountState(
    user: user != null ? user() : this.user,
    pending: pending != null ? pending() : this.pending,
    needsPassword: needsPassword ?? this.needsPassword,
    effect: effect,
  );

  @override
  List<Object?> get props => [user, pending, needsPassword];
}
