import 'package:di/di.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/features/account/presentation/bloc/account_bloc.dart';
import 'package:saldough/shared/auth/auth.dart';

/// Lingkup dependensi layar Akun (ADR-023).
///
/// Dibuat saat layar Akun dibuka dan dibuang saat ditutup, seperti
/// `FreelanceScope` — bukan tujuan navigasi bawah. `AuthRepository` dan
/// `CurrencyPreferenceRepository` didaftarkan di `RootModule` dan dibawa
/// lewat [bridge].
final class AccountScope extends IsolatedScope {
  /// Membuat [AccountScope] dengan kontainer induk [parentContainer].
  AccountScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<AuthRepository>(parent<AuthRepository>())
      ..registerSingleton<CurrencyPreferenceRepository>(parent<CurrencyPreferenceRepository>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<AccountBloc>(
      () => AccountBloc(authRepository: c<AuthRepository>(), currencyRepository: c<CurrencyPreferenceRepository>()),
      dispose: (bloc) => bloc.close(),
    );
  }
}
