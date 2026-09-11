import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/investment/domain/entities/allocation_percentage.dart';
import 'package:saldough/features/investment/domain/entities/cycle_investment_snapshot.dart';
import 'package:saldough/features/investment/domain/entities/goal_loan.dart';
import 'package:saldough/features/investment/domain/repositories/cycle_investment_gateway.dart';
import 'package:saldough/features/investment/domain/repositories/goal_loan_repository.dart';
import 'package:saldough/features/investment/domain/usecases/calculate_allocations.dart';
import 'package:saldough/features/investment/domain/usecases/calculate_goal_balances.dart';
import 'package:saldough/shared/goal/goal.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

class MockGoalLoanRepository extends Mock implements GoalLoanRepository {}

class MockCycleInvestmentGateway extends Mock implements CycleInvestmentGateway {}

void main() {
  late MockGoalRepository goalRepository;
  late MockGoalLoanRepository loanRepository;
  late MockCycleInvestmentGateway gateway;

  setUp(() {
    goalRepository = MockGoalRepository();
    loanRepository = MockGoalLoanRepository();
    gateway = MockCycleInvestmentGateway();
  });

  CalculateGoalBalances buildUseCase() => CalculateGoalBalances(
        goalRepository: goalRepository,
        loanRepository: loanRepository,
        gateway: gateway,
        calculateAllocations: CalculateAllocations(),
      );

  group('CalculateGoalBalances', () {
    test('menggabungkan saldo awal, alokasi siklus tertutup, dan pinjaman', () async {
      when(() => goalRepository.listGoals()).thenAnswer(
        (_) async => right(const [
          Goal(id: 'a', name: 'Pos A', openingBalance: 100000000),
          Goal(id: 'b', name: 'Pos B', openingBalance: 0),
        ]),
      );
      when(() => loanRepository.listLoans()).thenAnswer(
        (_) async => right([
          GoalLoan(
            id: 'l1',
            fromGoalId: 'a',
            toGoalId: 'b',
            principal: 10000000,
            repaid: 10000000,
            date: DateTime(2026, 9, 2),
          ),
        ]),
      );
      when(() => gateway.listClosedCycleSnapshots()).thenAnswer(
        (_) async => right(const [
          CycleInvestmentSnapshot(
            cycleId: '2026-08',
            remainder: 100000000,
            returnDeposit: 0,
            allocations: [
              AllocationPercentage(goalId: 'a', percentage: 20),
              AllocationPercentage(goalId: 'b', percentage: 80),
            ],
            isClosed: true,
          ),
        ]),
      );

      final result = await buildUseCase().call();

      final balances = result.getOrElse((_) => throw StateError('expected Right'));
      expect(balances['a'], 100000000 + 20000000 - 10000000);
      expect(balances['b'], 0 + 80000000 + 10000000);
    });

    test('siklus belum dialokasikan (persentase 0) tidak menyumbang saldo', () async {
      when(() => goalRepository.listGoals()).thenAnswer(
        (_) async => right(const [Goal(id: 'a', name: 'Pos A', openingBalance: 500000)]),
      );
      when(() => loanRepository.listLoans()).thenAnswer((_) async => right(const []));
      when(() => gateway.listClosedCycleSnapshots()).thenAnswer(
        (_) async => right(const [
          CycleInvestmentSnapshot(
            cycleId: '2026-08',
            remainder: 100000000,
            returnDeposit: 0,
            allocations: [],
            isClosed: true,
          ),
        ]),
      );

      final result = await buildUseCase().call();

      final balances = result.getOrElse((_) => throw StateError('expected Right'));
      expect(balances['a'], 500000);
    });
  });
}
