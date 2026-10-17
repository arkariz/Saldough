import 'package:di/di.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Scope Analisis: hanya membaca transaksi dan mendengarkan `LedgerChanges`.
final class AnalysisScope extends IsolatedScope {
  /// Membuat [AnalysisScope] dengan kontainer induk [parentContainer].
  AnalysisScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<TransactionRepository>(parent<TransactionRepository>())
      ..registerSingleton<WalletRepository>(parent<WalletRepository>())
      ..registerSingleton<LedgerChanges>(parent<LedgerChanges>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<AnalysisBloc>(
      () => AnalysisBloc(
        transactionRepository: c<TransactionRepository>(),
        walletRepository: c<WalletRepository>(),
        ledgerChanges: c<LedgerChanges>(),
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
