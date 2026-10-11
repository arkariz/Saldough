import 'package:di/di.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup dependensi fitur `record` (lembar CATAT). `WalletRepository` dan
/// `TransactionRepository` sudah didaftarkan di `RootModule` sebagai
/// repository bersama (ADR-0009 — keduanya dipakai fitur lain juga di fase
/// selanjutnya), jadi cukup dibawa lewat [bridge]. `RecomputeWalletBalances`
/// dan `RecordTransaction` adalah use case murni (bukan repository), jadi
/// diinstansiasi langsung di [register], bukan diambil dari kontainer induk.
final class RecordScope extends IsolatedScope {
  /// Membuat [RecordScope] dengan kontainer induk [parentContainer].
  RecordScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<WalletRepository>(parent<WalletRepository>())
      ..registerSingleton<TransactionRepository>(parent<TransactionRepository>())
      ..registerSingleton<LedgerChanges>(parent<LedgerChanges>())
      ..registerSingleton<BudgetItemCatalog>(parent<BudgetItemCatalog>())
      ..registerSingleton<CategoryRepository>(parent<CategoryRepository>())
      ..registerSingleton<RecurringRuleRepository>(parent<RecurringRuleRepository>())
      ..registerSingleton<RecurringChanges>(parent<RecurringChanges>());
    // Tawaran awal bulan (FINANCIAL_PERIOD F2); sebagian uji tidak
    // menyediakannya.
    if (parent.isRegistered<FinancialMonthPreferenceRepository>()) {
      c.registerSingleton<FinancialMonthPreferenceRepository>(parent<FinancialMonthPreferenceRepository>());
    }
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<RecordBloc>(
      () => RecordBloc(
        walletRepository: c<WalletRepository>(),
        transactionRepository: c<TransactionRepository>(),
        budgetItemCatalog: c<BudgetItemCatalog>(),
        createCategory: CreateCategory(repository: c<CategoryRepository>()),
        recurringRepository: c<RecurringRuleRepository>(),
        recurringChanges: c<RecurringChanges>(),
        financialMonth: c.isRegistered<FinancialMonthPreferenceRepository>()
            ? c<FinancialMonthPreferenceRepository>()
            : null,
        recordTransaction: RecordTransaction(
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
