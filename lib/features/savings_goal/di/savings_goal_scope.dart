import 'package:di/di.dart';
import 'package:saldough/features/savings_goal/presentation/bloc/savings_goal_bloc.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup dependensi fitur tujuan tabungan (ADR-048 §3.8). Repositori
/// bersama dibawa dari `RootModule`.
final class SavingsGoalScope extends IsolatedScope {
  /// Membuat [SavingsGoalScope] dengan kontainer induk [parentContainer].
  SavingsGoalScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<SavingsGoalRepository>(parent<SavingsGoalRepository>())
      ..registerSingleton<SavingsGoalDraftStore>(parent<SavingsGoalDraftStore>())
      ..registerSingleton<WalletRepository>(parent<WalletRepository>())
      ..registerSingleton<TransactionRepository>(parent<TransactionRepository>())
      ..registerSingleton<LedgerChanges>(parent<LedgerChanges>());
    // Perkiraan Plus (ADR-048 §3.6); sebagian uji tidak menyediakannya.
    if (parent.isRegistered<IdleMoneyAverage>()) {
      c.registerSingleton<IdleMoneyAverage>(parent<IdleMoneyAverage>());
    }
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<SavingsGoalBloc>(
      () => SavingsGoalBloc(
        goals: c<SavingsGoalRepository>(),
        wallets: c<WalletRepository>(),
        transactions: c<TransactionRepository>(),
        ledgerChanges: c<LedgerChanges>(),
        idleMoney: c.isRegistered<IdleMoneyAverage>() ? c<IdleMoneyAverage>() : null,
        recordTransaction: RecordTransaction(
          transferOnlyWallets: GoalTransferOnlyWallets(c<SavingsGoalRepository>()),
          ledgerChanges: c<LedgerChanges>(),
          transactionRepository: c<TransactionRepository>(),
          recomputeWalletBalances: RecomputeWalletBalances(
            walletRepository: c<WalletRepository>(),
            transactionRepository: c<TransactionRepository>(),
          ),
        ),
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
