import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:saldough/features/investment/data/repositories/goal_loan_repository_impl.dart';
import 'package:saldough/features/investment/domain/repositories/cycle_investment_gateway.dart';
import 'package:saldough/features/investment/domain/repositories/goal_loan_repository.dart';
import 'package:saldough/features/investment/domain/usecases/calculate_allocations.dart';
import 'package:saldough/features/investment/domain/usecases/calculate_goal_balances.dart';
import 'package:saldough/features/investment/presentation/bloc/investment_bloc.dart';
import 'package:saldough/shared/goal/goal.dart';

/// Lingkup dependensi fitur `investment`. Membawa [KeyValueStorage] dan
/// [GoalRepository] dari induk (keduanya sudah root-level — lihat
/// ADR-0009), dan [CycleInvestmentGateway] yang juga dikawat di
/// `RootModule` (port milik `investment` sendiri, diimplementasikan
/// `features/cycle/data/` — pola yang sama seperti `CycleIncomeWriter`).
final class InvestmentScope extends IsolatedScope {
  /// Membuat [InvestmentScope] dengan kontainer induk [parentContainer].
  InvestmentScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<KeyValueStorage>(parent<KeyValueStorage>())
      ..registerSingleton<GoalRepository>(parent<GoalRepository>())
      ..registerSingleton<CycleInvestmentGateway>(parent<CycleInvestmentGateway>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<GoalLoanRepository>(
      () => GoalLoanRepositoryImpl(storage: c<KeyValueStorage>()),
    );
    c.registerLazySingleton<CalculateAllocations>(CalculateAllocations.new);
    c.registerLazySingleton<CalculateGoalBalances>(
      () => CalculateGoalBalances(
        goalRepository: c<GoalRepository>(),
        loanRepository: c<GoalLoanRepository>(),
        gateway: c<CycleInvestmentGateway>(),
        calculateAllocations: c<CalculateAllocations>(),
      ),
    );
    c.registerLazySingleton<InvestmentBloc>(
      () => InvestmentBloc(
        goalRepository: c<GoalRepository>(),
        loanRepository: c<GoalLoanRepository>(),
        gateway: c<CycleInvestmentGateway>(),
        calculateGoalBalances: c<CalculateGoalBalances>(),
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
