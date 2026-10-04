import 'package:di/di.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup dependensi fitur `recurring`. Repository dan kedua sinyal
/// tinggal di akar dan dibawa lewat [bridge]. [monthsBack] menentukan berapa
/// bulan transaksi yang dibaca bloc: 1 untuk segmen Rutin, 12 untuk
/// rincian rutin.
final class RecurringScope extends IsolatedScope {
  /// Membuat [RecurringScope].
  RecurringScope({required super.parentContainer, this.monthsBack = 1});

  /// Lihat [RecurringScope].
  final int monthsBack;

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<RecurringRuleRepository>(parent<RecurringRuleRepository>())
      ..registerSingleton<RecurringChanges>(parent<RecurringChanges>())
      ..registerSingleton<TransactionRepository>(parent<TransactionRepository>())
      ..registerSingleton<WalletRepository>(parent<WalletRepository>())
      ..registerSingleton<LedgerChanges>(parent<LedgerChanges>());
    // Tautan rutin ke pos (ADR-036 §3.4); sebagian uji tidak menyediakannya.
    if (parent.isRegistered<BudgetItemCatalog>()) {
      c.registerSingleton<BudgetItemCatalog>(parent<BudgetItemCatalog>());
    }
    // Saran Sepertinya rutin (ADR-037 §3.3).
    if (parent.isRegistered<RecurringSuggestionDismissals>()) {
      c.registerSingleton<RecurringSuggestionDismissals>(parent<RecurringSuggestionDismissals>());
    }
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<RecurringBloc>(
      () => RecurringBloc(
        rules: c<RecurringRuleRepository>(),
        transactions: c<TransactionRepository>(),
        wallets: c<WalletRepository>(),
        ledgerChanges: c<LedgerChanges>(),
        recurringChanges: c<RecurringChanges>(),
        budgetItemCatalog: c.isRegistered<BudgetItemCatalog>() ? c<BudgetItemCatalog>() : null,
        suggestionDismissals: c.isRegistered<RecurringSuggestionDismissals>()
            ? c<RecurringSuggestionDismissals>()
            : null,
        recordTransaction: RecordTransaction(
          ledgerChanges: c<LedgerChanges>(),
          transactionRepository: c<TransactionRepository>(),
          recomputeWalletBalances: RecomputeWalletBalances(
            walletRepository: c<WalletRepository>(),
            transactionRepository: c<TransactionRepository>(),
          ),
        ),
        monthsBack: monthsBack,
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
