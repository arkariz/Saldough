import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/investment/domain/repositories/cycle_investment_gateway.dart';
import 'package:saldough/features/investment/domain/repositories/goal_loan_repository.dart';
import 'package:saldough/features/investment/domain/usecases/calculate_allocations.dart';
import 'package:saldough/shared/goal/goal.dart';

/// Menghitung saldo seluruh pos tujuan dari saldo awal, alokasi siklus
/// tertutup, dan pinjaman (T-5.7/FR-INV-005). Lihat DOMAIN_MODEL.md bagian
/// "Pos tujuan dan pinjaman" untuk rumusnya.
final class CalculateGoalBalances {
  /// Membuat [CalculateGoalBalances].
  CalculateGoalBalances({
    required this._goalRepository,
    required this._loanRepository,
    required this._gateway,
    required this._calculateAllocations,
  });

  final GoalRepository _goalRepository;
  final GoalLoanRepository _loanRepository;
  final CycleInvestmentGateway _gateway;
  final CalculateAllocations _calculateAllocations;

  /// Menghitung saldo tiap pos, dikembalikan sebagai map `goalId` → saldo
  /// dalam sen.
  Future<Either<Failure, Map<String, int>>> call() async {
    final goalsResult = await _goalRepository.listGoals();
    if (goalsResult case Left(value: final failure)) return left(failure);
    final goals = switch (goalsResult) { Right(value: final g) => g, _ => throw StateError('unreachable') };

    final loansResult = await _loanRepository.listLoans();
    if (loansResult case Left(value: final failure)) return left(failure);
    final loans = switch (loansResult) { Right(value: final l) => l, _ => throw StateError('unreachable') };

    final snapshotsResult = await _gateway.listClosedCycleSnapshots();
    if (snapshotsResult case Left(value: final failure)) return left(failure);
    final snapshots = switch (snapshotsResult) { Right(value: final s) => s, _ => throw StateError('unreachable') };

    final allocationAmounts = [
      for (final snapshot in snapshots)
        ..._calculateAllocations(investmentBudget: snapshot.investmentBudget, allocations: snapshot.allocations),
    ];

    return right({
      for (final goal in goals)
        goal.id: goal.openingBalance +
            allocationAmounts.where((a) => a.goalId == goal.id).fold<int>(0, (sum, a) => sum + a.amount) +
            loans.where((l) => l.toGoalId == goal.id).fold<int>(0, (sum, l) => sum + l.repaid) -
            loans.where((l) => l.fromGoalId == goal.id).fold<int>(0, (sum, l) => sum + l.principal),
    });
  }
}
