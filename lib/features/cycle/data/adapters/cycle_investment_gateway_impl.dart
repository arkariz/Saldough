import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/cycle/domain/entities/allocation.dart';
import 'package:saldough/features/cycle/domain/entities/investment_plan.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:saldough/features/cycle/domain/usecases/calculate_cycle_totals.dart';
import 'package:saldough/features/investment/domain/entities/allocation_percentage.dart';
import 'package:saldough/features/investment/domain/entities/cycle_investment_snapshot.dart';
import 'package:saldough/features/investment/domain/repositories/cycle_investment_gateway.dart';

/// Implementasi [CycleInvestmentGateway] (port milik fitur `investment`) di
/// atas [CycleRepository] fitur ini sendiri — lihat catatan revisi ADR-0009
/// bagian "Tujuh fitur MVP". `investment` tidak pernah mengimpor
/// `CycleRepository` atau `MonthlyCycle` secara langsung; satu-satunya yang
/// dibagikan adalah antarmuka kecil [CycleInvestmentGateway] ini, dikawat di
/// `RootModule`.
final class CycleInvestmentGatewayImpl implements CycleInvestmentGateway {
  /// Membuat [CycleInvestmentGatewayImpl] di atas [_cycleRepository].
  const CycleInvestmentGatewayImpl({required this._cycleRepository});

  final CycleRepository _cycleRepository;

  @override
  Future<Either<Failure, CycleInvestmentSnapshot?>> getSnapshot(
    String cycleId,
  ) async {
    final result = await _cycleRepository.getCycle(cycleId);
    return switch (result) {
      Left(value: final failure) => left(failure),
      Right(value: null) => const Right(null),
      Right(value: final cycle?) => right(_toSnapshot(cycle)),
    };
  }

  @override
  Future<Either<Failure, Unit>> saveAllocationPlan({
    required String cycleId,
    required int returnDeposit,
    required List<AllocationPercentage> allocations,
  }) async {
    final cycleResult = await _cycleRepository.getCycle(cycleId);
    if (cycleResult case Left(value: final failure)) return left(failure);
    if (cycleResult case Right(value: null)) {
      return left(
        BusinessRuleFailure(
          code: const FailureCode('CYCLE_NOT_FOUND'),
          message: 'Siklus $cycleId belum ada, tidak bisa disunting.',
          userMessage: 'Siklus $cycleId belum ada.',
        ),
      );
    }
    final cycle = switch (cycleResult) {
      Right(value: final c?) => c,
      _ => throw StateError('unreachable'),
    };
    if (cycle.isClosed) {
      return left(
        BusinessRuleFailure(
          code: const FailureCode('CYCLE_CLOSED'),
          message: 'Siklus $cycleId sudah ditutup, tidak bisa disunting.',
          userMessage: 'Siklus $cycleId sudah ditutup. Buka kembali dulu.',
        ),
      );
    }

    final plan = InvestmentPlan(
      returnDeposit: returnDeposit,
      allocations: [
        for (final allocation in allocations)
          Allocation(
            goalId: allocation.goalId,
            percentage: allocation.percentage,
          ),
      ],
    );
    return _cycleRepository.saveCycle(cycle.copyWith(investmentPlan: plan));
  }

  @override
  Future<Either<Failure, List<CycleInvestmentSnapshot>>>
  listClosedCycleSnapshots() async {
    final idsResult = await _cycleRepository.listCycleIds();
    if (idsResult case Left(value: final failure)) return left(failure);
    final ids = switch (idsResult) {
      Right(value: final i) => i,
      _ => throw StateError('unreachable'),
    };

    final snapshots = <CycleInvestmentSnapshot>[];
    for (final id in ids) {
      final result = await _cycleRepository.getCycle(id);
      if (result case Left(value: final failure)) return left(failure);
      if (result case Right(value: final cycle?) when cycle.isClosed) {
        snapshots.add(_toSnapshot(cycle));
      }
    }
    return right(snapshots);
  }

  @override
  Future<Either<Failure, List<String>>> listCycleIds() => _cycleRepository.listCycleIds();

  CycleInvestmentSnapshot _toSnapshot(MonthlyCycle cycle) {
    final totals = CalculateCycleTotals().call(cycle);
    return CycleInvestmentSnapshot(
      cycleId: cycle.id,
      remainder: totals.remainder,
      returnDeposit: cycle.investmentPlan.returnDeposit,
      allocations: [
        for (final allocation in cycle.investmentPlan.allocations)
          AllocationPercentage(
            goalId: allocation.goalId,
            percentage: allocation.percentage,
          ),
      ],
      isClosed: cycle.isClosed,
    );
  }
}
