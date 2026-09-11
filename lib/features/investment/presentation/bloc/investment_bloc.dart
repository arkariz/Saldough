import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/investment/domain/entities/allocation_percentage.dart';
import 'package:saldough/features/investment/domain/entities/cycle_investment_snapshot.dart';
import 'package:saldough/features/investment/domain/entities/goal_loan.dart';
import 'package:saldough/features/investment/domain/repositories/cycle_investment_gateway.dart';
import 'package:saldough/features/investment/domain/repositories/goal_loan_repository.dart';
import 'package:saldough/features/investment/domain/usecases/calculate_goal_balances.dart';
import 'package:saldough/features/investment/domain/usecases/validate_allocation_total.dart';
import 'package:saldough/features/investment/presentation/bloc/investment_state.dart';
import 'package:saldough/shared/goal/goal.dart';
import 'package:state_management/state_management.dart';

part 'investment_effect.dart';
part 'investment_event.dart';

/// Bloc layar investasi: kelola pos tujuan, alokasi bulanan, pinjaman antar
/// pos, dan saldo (FR-INV-001 sampai FR-INV-005).
final class InvestmentBloc extends Bloc<InvestmentEvent, InvestmentState> {
  /// Membuat [InvestmentBloc].
  InvestmentBloc({
    required this._goalRepository,
    required this._loanRepository,
    required this._gateway,
    required this._calculateGoalBalances,
  }) : super(InvestmentState.initial()) {
    on<InvestmentOpened>(_onOpened);
    on<InvestmentCycleSelected>(_onCycleSelected);
    on<GoalSaved>(_onGoalSaved);
    on<GoalDeleted>(_onGoalDeleted);
    on<AllocationPlanSaved>(_onAllocationPlanSaved);
    on<GoalLoanSaved>(_onLoanSaved);
    on<GoalLoanDeleted>(_onLoanDeleted);
  }

  final GoalRepository _goalRepository;
  final GoalLoanRepository _loanRepository;
  final CycleInvestmentGateway _gateway;
  final CalculateGoalBalances _calculateGoalBalances;

  Future<void> _onOpened(InvestmentOpened event, Emitter<InvestmentState> emit) async {
    emit(state.copyWith(isLoading: true));
    await _reloadAll(emit);
  }

  Future<void> _onCycleSelected(InvestmentCycleSelected event, Emitter<InvestmentState> emit) async {
    emit(state.copyWith(cycleId: event.cycleId, isLoading: true));
    final result = await _gateway.getSnapshot(event.cycleId);
    switch (result) {
      case Left(value: final failure):
        emit(state.withSnapshot(null, effect: _effectError(failure)));
      case Right(value: final snapshot):
        emit(state.withSnapshot(snapshot));
    }
  }

  Future<void> _onGoalSaved(GoalSaved event, Emitter<InvestmentState> emit) async {
    final result = await _goalRepository.saveGoal(event.goal);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        await _reloadAll(emit);
    }
  }

  Future<void> _onGoalDeleted(GoalDeleted event, Emitter<InvestmentState> emit) async {
    final result = await _goalRepository.deleteGoal(event.id);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        await _reloadAll(emit);
    }
  }

  Future<void> _onAllocationPlanSaved(AllocationPlanSaved event, Emitter<InvestmentState> emit) async {
    if (!isValidAllocationTotal(event.allocations)) {
      emit(state.copyWith(effect: _effectInvalidTotal()));
      return;
    }
    final result = await _gateway.saveAllocationPlan(
      cycleId: state.cycleId,
      returnDeposit: event.returnDeposit,
      allocations: event.allocations,
    );
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        final snapshotResult = await _gateway.getSnapshot(state.cycleId);
        final snapshot = switch (snapshotResult) { Right(value: final s) => s, Left() => null };
        emit(state.withSnapshot(snapshot, effect: _effectAllocationSaved()));
    }
  }

  Future<void> _onLoanSaved(GoalLoanSaved event, Emitter<InvestmentState> emit) async {
    final result = await _loanRepository.saveLoan(event.loan);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        await _reloadAll(emit, effect: _effectLoanSaved());
    }
  }

  Future<void> _onLoanDeleted(GoalLoanDeleted event, Emitter<InvestmentState> emit) async {
    final result = await _loanRepository.deleteLoan(event.id);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        await _reloadAll(emit);
    }
  }

  Future<void> _reloadAll(Emitter<InvestmentState> emit, {UiEffect? effect}) async {
    final goalsResult = await _goalRepository.listGoals();
    if (goalsResult case Left(value: final failure)) {
      emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
      return;
    }
    final goals = switch (goalsResult) { Right(value: final g) => g, _ => throw StateError('unreachable') };

    final loansResult = await _loanRepository.listLoans();
    final loans = switch (loansResult) { Right(value: final l) => l, Left() => const <GoalLoan>[] };

    final balancesResult = await _calculateGoalBalances();
    final balances = switch (balancesResult) { Right(value: final b) => b, Left() => const <String, int>{} };

    final closedSnapshotsResult = await _gateway.listClosedCycleSnapshots();
    final closedSnapshots = switch (closedSnapshotsResult) {
      Right(value: final s) => s,
      Left() => const <CycleInvestmentSnapshot>[],
    };

    final snapshotResult = await _gateway.getSnapshot(state.cycleId);
    final snapshot = switch (snapshotResult) { Right(value: final s) => s, Left() => null };

    emit(InvestmentState(
      goals: goals,
      balances: balances,
      loans: loans,
      cycleId: state.cycleId,
      cycleSnapshot: snapshot,
      closedSnapshots: closedSnapshots,
      isLoading: false,
      effect: effect,
    ));
  }
}
