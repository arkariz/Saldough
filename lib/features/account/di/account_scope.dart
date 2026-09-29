import 'package:di/di.dart';
import 'package:saldough/features/account/presentation/bloc/account_bloc.dart';
import 'package:saldough/shared/auth/auth.dart';

/// Lingkup dependensi layar Akun (ADR-023).
///
/// Dibuat saat layar Akun dibuka dan dibuang saat ditutup, seperti
/// `FreelanceScope` — bukan tujuan navigasi bawah. `AuthRepository`
/// didaftarkan di `RootModule` dan dibawa lewat [bridge].
final class AccountScope extends IsolatedScope {
  /// Membuat [AccountScope] dengan kontainer induk [parentContainer].
  AccountScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c.registerSingleton<AuthRepository>(parent<AuthRepository>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<AccountBloc>(
      () => AccountBloc(authRepository: c<AuthRepository>()),
      dispose: (bloc) => bloc.close(),
    );
  }
}
