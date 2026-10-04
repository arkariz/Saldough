import 'package:di/di.dart';
import 'package:saldough/features/plan/domain/month_review.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/features/plan/presentation/bloc/plan_month_bloc.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup dependensi fitur `plan` (segmen Bulan ini, baris perkiraan
/// Beranda). Seluruh repository, port, dan sinyal tinggal di akar.
final class PlanScope extends IsolatedScope {
  /// Membuat [PlanScope].
  PlanScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<WalletRepository>(parent<WalletRepository>())
      ..registerSingleton<TransactionRepository>(parent<TransactionRepository>())
      ..registerSingleton<RecurringRuleRepository>(parent<RecurringRuleRepository>())
      ..registerSingleton<PlanBudgetSource>(parent<PlanBudgetSource>())
      ..registerSingleton<PlanFreelanceSource>(parent<PlanFreelanceSource>())
      ..registerSingleton<LedgerChanges>(parent<LedgerChanges>())
      ..registerSingleton<RecurringChanges>(parent<RecurringChanges>());
    // Tinjau awal bulan (ADR-036 §3.7); sebagian uji tidak menyediakannya.
    if (parent.isRegistered<MonthReviewRepository>()) {
      c.registerSingleton<MonthReviewRepository>(parent<MonthReviewRepository>());
    }
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<PlanMonthBloc>(
      () => PlanMonthBloc(
        wallets: c<WalletRepository>(),
        transactions: c<TransactionRepository>(),
        rules: c<RecurringRuleRepository>(),
        budgets: c<PlanBudgetSource>(),
        freelance: c<PlanFreelanceSource>(),
        ledgerChanges: c<LedgerChanges>(),
        recurringChanges: c<RecurringChanges>(),
        reviews: c.isRegistered<MonthReviewRepository>() ? c<MonthReviewRepository>() : null,
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
