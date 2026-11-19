import 'package:di/di.dart';
import 'package:saldough/core/financial_month/financial_period.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_activity_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wealth_history_bloc.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup dependensi fitur `wallet` (layar Dompet). Sama seperti
/// `TransactionScope`: `WalletRepository` dan `TransactionRepository` sudah
/// didaftarkan di `RootModule` sebagai repository bersama, jadi cukup dibawa
/// lewat [bridge]. `RecomputeWalletBalances` adalah use case murni, jadi
/// diinstansiasi langsung di [register].
final class WalletScope extends IsolatedScope {
  /// Membuat [WalletScope] dengan kontainer induk [parentContainer].
  WalletScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<WalletRepository>(parent<WalletRepository>())
      ..registerSingleton<TransactionRepository>(parent<TransactionRepository>())
      ..registerSingleton<LedgerChanges>(parent<LedgerChanges>())
      ..registerSingleton<SavingsGoalRepository>(parent<SavingsGoalRepository>());
    // Investasi (ADR-049); sebagian uji tidak menyediakannya.
    if (parent.isRegistered<InvestmentRepository>()) {
      c.registerSingleton<InvestmentRepository>(parent<InvestmentRepository>());
    }
    if (parent.isRegistered<RefreshSheetPrices>()) {
      c
        ..registerSingleton<RefreshSheetPrices>(parent<RefreshSheetPrices>())
        ..registerSingleton<PriceSheetLinkStore>(parent<PriceSheetLinkStore>())
        ..registerSingleton<ConnectPriceSheet>(parent<ConnectPriceSheet>());
    }
    if (parent.isRegistered<AuthRepository>()) c.registerSingleton<AuthRepository>(parent<AuthRepository>());
  }

  @override
  void register(GetIt c) {
    c
      ..registerLazySingleton<WalletBloc>(
        () => WalletBloc(
          ledgerChanges: c<LedgerChanges>(),
          walletRepository: c<WalletRepository>(),
          transactionRepository: c<TransactionRepository>(),
          goalRepository: c<SavingsGoalRepository>(),
          investmentRepository: c.isRegistered<InvestmentRepository>() ? c<InvestmentRepository>() : null,
          sheetPrices: c.isRegistered<RefreshSheetPrices>() ? c<RefreshSheetPrices>() : null,
          sheetLinks: c.isRegistered<PriceSheetLinkStore>() ? c<PriceSheetLinkStore>() : null,
          connectSheet: c.isRegistered<ConnectPriceSheet>() ? c<ConnectPriceSheet>() : null,
          isPlus: () => ActivePlan.isPlus,
          // Google Sheet hanya untuk yang masuk dengan Google (ADR-051 §3.2).
          isGoogleUser: () =>
              c.isRegistered<AuthRepository>() && c<AuthRepository>().currentUser?.method == SignInMethod.google,
          recordTransaction: RecordTransaction(
            transferOnlyWallets: parent.isRegistered<TransferOnlyWallets>() ? parent<TransferOnlyWallets>() : const NoTransferOnlyWallets(),
            ledgerChanges: c<LedgerChanges>(),
            transactionRepository: c<TransactionRepository>(),
            recomputeWalletBalances: RecomputeWalletBalances(
              walletRepository: c<WalletRepository>(),
              transactionRepository: c<TransactionRepository>(),
            ),
          ),
        ),
        dispose: (bloc) => bloc.close(),
      )
      // Riwayat rincian dompet (ADR-030 §3.3); hanya dibuat rute rincian.
      ..registerLazySingleton<WalletActivityBloc>(
        () => WalletActivityBloc(
          transactionRepository: c<TransactionRepository>(),
          ledgerChanges: c<LedgerChanges>(),
        ),
        dispose: (bloc) => bloc.close(),
      )
      // Riwayat kekayaan (B-100); hanya dibuat rute Riwayat kekayaan.
      ..registerLazySingleton<WealthHistoryBloc>(
        () => WealthHistoryBloc(
          walletRepository: c<WalletRepository>(),
          transactionRepository: c<TransactionRepository>(),
          goalRepository: c<SavingsGoalRepository>(),
          investmentRepository: c.isRegistered<InvestmentRepository>() ? c<InvestmentRepository>() : null,
          schedule: () => ActiveFinancialMonth.schedule,
          isPlus: () => ActivePlan.isPlus,
          freePeriods: () => ActivePlan.limits.value.freeAnalysisPeriods,
        ),
        dispose: (bloc) => bloc.close(),
      );
  }
}
