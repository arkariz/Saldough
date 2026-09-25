import 'package:di/di.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup dependensi fitur `budget` (layar Anggaran). Ketiga repository
/// didaftarkan di `RootModule` dan dibawa lewat [bridge]: `WalletRepository`
/// dan `TransactionRepository` hanya DIBACA di sini. `BudgetRepository` milik
/// fitur ini, tetapi instansnya tinggal di akar karena juga dibaca pemilih pos
/// anggaran CATAT dan rincian transaksi lewat port masing-masing (ADR-0009).
final class BudgetScope extends IsolatedScope {
  /// Membuat [BudgetScope] dengan kontainer induk [parentContainer].
  BudgetScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<BudgetRepository>(parent<BudgetRepository>())
      ..registerSingleton<WalletRepository>(parent<WalletRepository>())
      ..registerSingleton<TransactionRepository>(parent<TransactionRepository>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<BudgetBloc>(
      () => BudgetBloc(
        budgetRepository: c<BudgetRepository>(),
        walletRepository: c<WalletRepository>(),
        transactionRepository: c<TransactionRepository>(),
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
