import 'package:bloc_test/bloc_test.dart';
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
import 'package:saldough/features/investment/presentation/bloc/investment_bloc.dart';
import 'package:saldough/features/investment/presentation/bloc/investment_state.dart';
import 'package:saldough/shared/goal/goal.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

class MockGoalLoanRepository extends Mock implements GoalLoanRepository {}

class MockCycleInvestmentGateway extends Mock implements CycleInvestmentGateway {}

void main() {
  late MockGoalRepository goalRepository;
  late MockGoalLoanRepository loanRepository;
  late MockCycleInvestmentGateway gateway;

  const goal = Goal(id: 'a', name: 'Pos A', openingBalance: 0);
  final openSnapshot = CycleInvestmentSnapshot(
    cycleId: currentCycleId(),
    remainder: 100000000,
    returnDeposit: 0,
    allocations: const [],
    isClosed: false,
  );

  setUpAll(() {
    registerFallbackValue(const <AllocationPercentage>[]);
    registerFallbackValue(
      GoalLoan(id: 'fallback', fromGoalId: 'x', toGoalId: 'y', principal: 1, repaid: 1, date: DateTime(2026)),
    );
  });

  setUp(() {
    goalRepository = MockGoalRepository();
    loanRepository = MockGoalLoanRepository();
    gateway = MockCycleInvestmentGateway();
    // UX-09: `_onOpened` sekarang juga memuat daftar siklus untuk memilih
    // siklus bawaan yang masih terbuka — bawaan kosong (tetap memakai
    // `cycleId` awal `InvestmentState.initial()`), tes yang butuh daftar
    // sungguhan menimpa stub ini sendiri.
    when(() => gateway.listCycleIds()).thenAnswer((_) async => right(const []));
  });

  // CalculateGoalBalances sendiri final class (tidak bisa di-mock mocktail)
  // — dipakai instance sungguhan di atas repository/gateway yang
  // dipalsukan, sama seperti pola di worklog_bloc_test.dart.
  InvestmentBloc buildBloc() => InvestmentBloc(
        goalRepository: goalRepository,
        loanRepository: loanRepository,
        gateway: gateway,
        calculateGoalBalances: CalculateGoalBalances(
          goalRepository: goalRepository,
          loanRepository: loanRepository,
          gateway: gateway,
          calculateAllocations: CalculateAllocations(),
        ),
      );

  group('InvestmentBloc', () {
    blocTest<InvestmentBloc, InvestmentState>(
      'InvestmentOpened memuat pos, saldo, pinjaman, dan rencana siklus berjalan',
      build: () {
        when(() => goalRepository.listGoals()).thenAnswer((_) async => right([goal]));
        when(() => loanRepository.listLoans()).thenAnswer((_) async => right(const []));
        when(() => gateway.listClosedCycleSnapshots()).thenAnswer((_) async => right(const []));
        when(() => gateway.getSnapshot(any())).thenAnswer((_) async => right(openSnapshot));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const InvestmentOpened()),
      expect: () => [
        isA<InvestmentState>().having((s) => s.isLoading, 'isLoading', true),
        isA<InvestmentState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.goals, 'goals', [goal])
            .having((s) => s.cycleSnapshot, 'cycleSnapshot', openSnapshot),
      ],
    );

    // UX-09: siklus bawaan bukan lagi selalu bulan berjalan -- kalau ada
    // siklus yang sudah dibuat dan masih terbuka, pilih itu (yang terbaru),
    // bukan siklus yang sudah ditutup.
    blocTest<InvestmentBloc, InvestmentState>(
      'InvestmentOpened memilih siklus TERBUKA terbaru sebagai bawaan, bukan bulan berjalan',
      build: () {
        when(() => goalRepository.listGoals()).thenAnswer((_) async => right([goal]));
        when(() => loanRepository.listLoans()).thenAnswer((_) async => right(const []));
        when(() => gateway.listCycleIds()).thenAnswer(
          (_) async => right(const ['2026-08', '2026-09', '2026-10']),
        );
        when(() => gateway.listClosedCycleSnapshots()).thenAnswer(
          (_) async => right(const [
            CycleInvestmentSnapshot(
              cycleId: '2026-08',
              remainder: 0,
              returnDeposit: 0,
              allocations: [],
              isClosed: true,
            ),
            CycleInvestmentSnapshot(
              cycleId: '2026-09',
              remainder: 0,
              returnDeposit: 0,
              allocations: [],
              isClosed: true,
            ),
          ]),
        );
        when(() => gateway.getSnapshot(any())).thenAnswer((_) async => right(openSnapshot));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const InvestmentOpened()),
      expect: () => [
        isA<InvestmentState>().having((s) => s.cycleId, 'cycleId', '2026-10'),
        isA<InvestmentState>().having((s) => s.isLoading, 'isLoading', false),
      ],
      verify: (_) => verify(() => gateway.getSnapshot('2026-10')).called(1),
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'AllocationPlanSaved dengan total bukan 0/100 ditolak tanpa menulis',
      build: () {
        when(() => goalRepository.listGoals()).thenAnswer((_) async => right([goal]));
        when(() => loanRepository.listLoans()).thenAnswer((_) async => right(const []));
        when(() => gateway.listClosedCycleSnapshots()).thenAnswer((_) async => right(const []));
        when(() => gateway.getSnapshot(any())).thenAnswer((_) async => right(openSnapshot));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AllocationPlanSaved(
        returnDeposit: 0,
        allocations: [AllocationPercentage(goalId: 'a', percentage: 40)],
      )),
      expect: () => [
        isA<InvestmentState>().having((s) => s.effect, 'effect', isNotNull),
      ],
      verify: (_) => verifyNever(
        () => gateway.saveAllocationPlan(
          cycleId: any(named: 'cycleId'),
          returnDeposit: any(named: 'returnDeposit'),
          allocations: any(named: 'allocations'),
        ),
      ),
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'AllocationPlanSaved dengan total 100 menulis lewat gateway',
      build: () {
        when(() => gateway.saveAllocationPlan(
              cycleId: any(named: 'cycleId'),
              returnDeposit: any(named: 'returnDeposit'),
              allocations: any(named: 'allocations'),
            )).thenAnswer((_) async => right(unit));
        when(() => gateway.getSnapshot(any())).thenAnswer((_) async => right(openSnapshot));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AllocationPlanSaved(
        returnDeposit: 0,
        allocations: [AllocationPercentage(goalId: 'a', percentage: 100)],
      )),
      expect: () => [
        isA<InvestmentState>().having((s) => s.effect, 'effect', isNotNull),
      ],
      verify: (_) => verify(() => gateway.saveAllocationPlan(
            cycleId: any(named: 'cycleId'),
            returnDeposit: 0,
            allocations: [const AllocationPercentage(goalId: 'a', percentage: 100)],
          )).called(1),
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'GoalLoanSaved menyimpan lalu memuat ulang',
      build: () {
        when(() => loanRepository.saveLoan(any())).thenAnswer((_) async => right(unit));
        when(() => goalRepository.listGoals()).thenAnswer((_) async => right([goal]));
        when(() => loanRepository.listLoans()).thenAnswer((_) async => right(const []));
        when(() => gateway.listClosedCycleSnapshots()).thenAnswer((_) async => right(const []));
        when(() => gateway.getSnapshot(any())).thenAnswer((_) async => right(openSnapshot));
        return buildBloc();
      },
      act: (bloc) => bloc.add(GoalLoanSaved(
        GoalLoan(id: 'l1', fromGoalId: 'a', toGoalId: 'a', principal: 1000, repaid: 1000, date: DateTime(2026)),
      )),
      expect: () => [
        isA<InvestmentState>().having((s) => s.effect, 'effect', isNotNull),
      ],
      verify: (_) => verify(() => loanRepository.saveLoan(any())).called(1),
    );
  });
}
