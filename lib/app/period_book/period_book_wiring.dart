import 'dart:async';

import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:saldough/app/milestone/milestone_coordinator.dart';
import 'package:saldough/app/period_book/app_book_access.dart';
import 'package:saldough/app/period_book/app_period_book_source.dart';
import 'package:saldough/app/period_book/app_ritual_access.dart';
import 'package:saldough/app/period_book/app_settings_access.dart';
import 'package:saldough/app/period_book/app_shelf_access.dart';
import 'package:saldough/app/period_book/period_book_gate.dart';
import 'package:saldough/app/shell/shell_requests.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/analysis/domain/period_comparison.dart';
import 'package:saldough/features/period_book/data/period_book_memory_store_impl.dart';
import 'package:saldough/features/period_book/domain/repositories/period_book_memory_store.dart';
import 'package:saldough/features/period_book/domain/repositories/period_book_source.dart';
import 'package:saldough/features/period_book/presentation/period_book_read_access.dart';
import 'package:saldough/features/period_book/presentation/period_book_ritual_access.dart';
import 'package:saldough/features/period_book/presentation/period_book_settings_access.dart';
import 'package:saldough/features/period_book/presentation/period_book_shelf_access.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Mendaftarkan ingatan dan gerbang Buku Periode di akar (ADR-045 §3.1, §3.5).
/// Dipanggil sesudah hak Plus dan repositori bersama terdaftar.
void registerPeriodBook(GetIt container) {
  container
    ..registerLazySingleton<PeriodBookMemoryStore>(
      () => PeriodBookMemoryStoreImpl(storage: container<KeyValueStorage>()),
    )
    ..registerLazySingleton<PeriodBookSource>(
      () => AppPeriodBookSource(
        transactions: container<TransactionRepository>(),
        categories: container<CategoryRepository>(),
        schedule: container<FinancialMonthPreferenceRepository>(),
        rules: container<RecurringRuleRepository>(),
        budgets: container<PlanBudgetSource>(),
        highlightMinSen: () => highlightMinSenOf(ActiveCurrency.value),
      ),
    )
    ..registerLazySingleton<ShellRequests>(ShellRequests.new)
    ..registerLazySingleton<PeriodBookRitualAccess>(
      () => AppRitualAccess(
        gate: container<PeriodBookGate>(),
        source: container<PeriodBookSource>(),
        transactions: container<TransactionRepository>(),
        wallets: container<WalletRepository>(),
        shell: container<ShellRequests>(),
      ),
    )
    ..registerLazySingleton<PeriodBookReadAccess>(
      () => AppBookAccess(
        gate: container<PeriodBookGate>(),
        source: container<PeriodBookSource>(),
        transactions: container<TransactionRepository>(),
        wallets: container<WalletRepository>(),
        absorbStamps: (ids) {
          // Stempel periode tampil di sampul; tanpa perayaan terpisah (BP-13).
          if (container.isRegistered<MilestoneCoordinator>()) {
            unawaited(container<MilestoneCoordinator>().absorbIntoCover(ids));
          }
        },
      ),
    )
    ..registerLazySingleton<PeriodBookShelfAccess>(() => AppShelfAccess(container<PeriodBookGate>()))
    ..registerLazySingleton<PeriodBookSettingsAccess>(() => AppSettingsAccess(container<PeriodBookGate>()))
    ..registerLazySingleton<PeriodBookGate>(
      () => PeriodBookGate(
        entitlements: container<Entitlements>(),
        memory: container<PeriodBookMemoryStore>(),
        transactions: container<TransactionRepository>(),
        schedule: container<FinancialMonthPreferenceRepository>(),
      ),
    );
}
