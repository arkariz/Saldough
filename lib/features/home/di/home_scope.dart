import 'package:di/di.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';
import 'package:saldough/features/home/presentation/bloc/home_bloc.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup dependensi fitur `home` (Beranda). Repository dompet/transaksi dan
/// kedua port ringkasan (ADR-0009) sudah didaftarkan di `RootModule`, jadi
/// cukup dibawa lewat [bridge].
final class HomeScope extends IsolatedScope {
  /// Membuat [HomeScope] dengan kontainer induk [parentContainer].
  HomeScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<WalletRepository>(parent<WalletRepository>())
      ..registerSingleton<TransactionRepository>(parent<TransactionRepository>())
      ..registerSingleton<LedgerChanges>(parent<LedgerChanges>())
      ..registerSingleton<BudgetOverviewSource>(parent<BudgetOverviewSource>())
      ..registerSingleton<FreelanceOverviewSource>(parent<FreelanceOverviewSource>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<HomeBloc>(
      () => HomeBloc(
        ledgerChanges: c<LedgerChanges>(),
        walletRepository: c<WalletRepository>(),
        transactionRepository: c<TransactionRepository>(),
        budgetOverviewSource: c<BudgetOverviewSource>(),
        freelanceOverviewSource: c<FreelanceOverviewSource>(),
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
