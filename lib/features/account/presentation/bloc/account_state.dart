import 'package:saldough/shared/auth/auth.dart';
import 'package:state_management/state_management.dart';

/// Status layar Akun (ADR-023): belum masuk, sedang memproses, atau sudah
/// masuk sebagai [user].
final class AccountState extends UiState<AccountState> {
  /// Membuat [AccountState].
  const AccountState({required this.user, this.isBusy = false, super.effect});

  /// State awal, sebelum status masuk diketahui.
  factory AccountState.initial() => const AccountState(user: null);

  /// Pengguna yang sedang masuk, atau `null` kalau belum/tidak lagi masuk.
  final AppUser? user;

  /// Sedang memproses masuk/keluar/hapus akun — tombol dinonaktifkan
  /// selagi ini `true` supaya tidak terkirim dobel.
  final bool isBusy;

  @override
  AccountState copyWith({AppUser? Function()? user, bool? isBusy, UiEffect? effect}) => AccountState(
        user: user != null ? user() : this.user,
        isBusy: isBusy ?? this.isBusy,
        effect: effect,
      );

  @override
  List<Object?> get props => [user, isBusy];
}
