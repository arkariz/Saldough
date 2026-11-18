import 'package:di/di.dart';
import 'package:saldough/features/investment/presentation/bloc/investment_bloc.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup dependensi fitur investasi (ADR-049 §3.10). Repositori bersama
/// dibawa dari `RootModule`.
final class InvestmentScope extends IsolatedScope {
  /// Membuat [InvestmentScope] dengan kontainer induk [parentContainer].
  InvestmentScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<InvestmentRepository>(parent<InvestmentRepository>())
      ..registerSingleton<InstrumentDraftStore>(parent<InstrumentDraftStore>())
      ..registerSingleton<WalletRepository>(parent<WalletRepository>())
      ..registerSingleton<TransactionRepository>(parent<TransactionRepository>())
      ..registerSingleton<LedgerChanges>(parent<LedgerChanges>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<InvestmentBloc>(
      () => InvestmentBloc(
        investments: c<InvestmentRepository>(),
        transactions: c<TransactionRepository>(),
        wallets: c<WalletRepository>(),
        ledgerChanges: c<LedgerChanges>(),
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
