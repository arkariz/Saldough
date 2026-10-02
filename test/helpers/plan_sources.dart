import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// [PlanBudgetSource] tanpa anggaran, untuk kontainer uji shell.
final class EmptyPlanBudgetSource implements PlanBudgetSource {
  /// Membuat [EmptyPlanBudgetSource].
  const EmptyPlanBudgetSource();

  @override
  Future<Either<Failure, List<PlanBudget>>> budgetsStartingIn(DateTime from, DateTime until) async => right(const []);
}

/// [PlanFreelanceSource] tanpa pembayaran, untuk kontainer uji shell.
final class EmptyPlanFreelanceSource implements PlanFreelanceSource {
  /// Membuat [EmptyPlanFreelanceSource].
  const EmptyPlanFreelanceSource();

  @override
  Future<Either<Failure, List<UncertainIncome>>> unpaid() async => right(const []);
}
