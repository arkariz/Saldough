import 'package:di/di.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/features/account/presentation/bloc/account_bloc.dart';
import 'package:saldough/features/account/presentation/bloc/category_manager_bloc.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/category/category.dart';

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
      ..registerSingleton<CurrencyPreferenceRepository>(parent<CurrencyPreferenceRepository>())
      ..registerSingleton<CategoryRepository>(parent<CategoryRepository>())
      ..registerSingleton<ChangeAppLanguage>(parent<ChangeAppLanguage>());
  }

  @override
  void register(GetIt c) {
    c
      ..registerLazySingleton<AccountBloc>(
        () => AccountBloc(
          authRepository: c<AuthRepository>(),
          currencyRepository: c<CurrencyPreferenceRepository>(),
          changeLanguage: c<ChangeAppLanguage>(),
        ),
        dispose: (bloc) => bloc.close(),
      )
      // Layar Kategori (ADR-026 §3.6), dibuka dari layar Akun.
      ..registerLazySingleton<CategoryManagerBloc>(
        () => CategoryManagerBloc(
          repository: c<CategoryRepository>(),
          createCategory: CreateCategory(repository: c<CategoryRepository>()),
        ),
        dispose: (bloc) => bloc.close(),
      );
  }
}
