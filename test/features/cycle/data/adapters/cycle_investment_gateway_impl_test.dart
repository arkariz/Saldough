import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/cycle/data/adapters/cycle_investment_gateway_impl.dart';
import 'package:saldough/features/cycle/data/repositories/cycle_repository_impl.dart';
import 'package:saldough/features/cycle/data/roll_up/unavailable_roll_up_resolver.dart';
import 'package:saldough/features/cycle/domain/entities/allocation.dart';
import 'package:saldough/features/cycle/domain/entities/income_line.dart';
import 'package:saldough/features/cycle/domain/entities/investment_plan.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:saldough/features/investment/domain/entities/allocation_percentage.dart';
import 'package:saldough/shared/income/income.dart';

CycleRepositoryImpl _buildRepository(InMemoryKeyValueStorage storage) =>
    CycleRepositoryImpl(
      storage: storage,
      resolver: const UnavailableRollUpResolver(),
      incomeSourceRepository: IncomeSourceRepositoryImpl(storage: storage),
    );

void main() {
  late InMemoryKeyValueStorage storage;
  late CycleInvestmentGatewayImpl gateway;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    gateway = CycleInvestmentGatewayImpl(
      cycleRepository: _buildRepository(storage),
    );
  });

  group('CycleInvestmentGatewayImpl', () {
    test(
      'getSnapshot membaca remainder, returnDeposit, alokasi, dan status tutup',
      () async {
        final repository = _buildRepository(storage);
        await repository.saveCycle(
          const MonthlyCycle(
            id: '2026-09',
            incomeLines: [
              IncomeLine(id: 'i1', label: 'Gaji', amount: 500000000),
            ],
            budgetLines: [],
            investmentPlan: InvestmentPlan(
              returnDeposit: 20000000,
              allocations: [Allocation(goalId: 'a', percentage: 50)],
            ),
          ),
        );

        final result = await gateway.getSnapshot('2026-09');

        final snapshot = result.getOrElse(
          (_) => throw StateError('expected Right'),
        );
        expect(snapshot, isNotNull);
        expect(snapshot!.remainder, 500000000);
        expect(snapshot.returnDeposit, 20000000);
        expect(snapshot.investmentBudget, 520000000);
        expect(
          snapshot.allocations.single,
          const AllocationPercentage(goalId: 'a', percentage: 50),
        );
        expect(snapshot.isClosed, isFalse);
      },
    );

    test(
      'getSnapshot mengembalikan Right(null) untuk siklus yang belum ada',
      () async {
        final result = await gateway.getSnapshot('2099-01');
        expect(
          result.getOrElse((_) => throw StateError('expected Right')),
          isNull,
        );
      },
    );

    test(
      'saveAllocationPlan menimpa rencana investasi siklus terbuka',
      () async {
        final repository = _buildRepository(storage);
        await repository.saveCycle(MonthlyCycle.empty('2026-09'));

        final saveResult = await gateway.saveAllocationPlan(
          cycleId: '2026-09',
          returnDeposit: 10000000,
          allocations: const [
            AllocationPercentage(goalId: 'a', percentage: 100),
          ],
        );
        expect(saveResult.isRight(), isTrue);

        final snapshotResult = await gateway.getSnapshot('2026-09');
        final snapshot = snapshotResult.getOrElse(
          (_) => throw StateError('expected Right'),
        );
        expect(snapshot!.returnDeposit, 10000000);
        expect(snapshot.allocations.single.percentage, 100);
      },
    );

    test('saveAllocationPlan menolak siklus yang belum ada', () async {
      final result = await gateway.saveAllocationPlan(
        cycleId: '2099-01',
        returnDeposit: 0,
        allocations: const [],
      );
      expect(result.isLeft(), isTrue);
    });

    test(
      'saveAllocationPlan menolak siklus yang sudah ditutup (ADR-0008)',
      () async {
        final repository = _buildRepository(storage);
        await repository.saveCycle(MonthlyCycle.empty('2026-08').close());

        final result = await gateway.saveAllocationPlan(
          cycleId: '2026-08',
          returnDeposit: 0,
          allocations: const [
            AllocationPercentage(goalId: 'a', percentage: 100),
          ],
        );
        expect(result.isLeft(), isTrue);
      },
    );

    test(
      'listClosedCycleSnapshots hanya mengembalikan siklus yang sudah ditutup',
      () async {
        final repository = _buildRepository(storage);
        await repository.saveCycle(MonthlyCycle.empty('2026-08').close());
        await repository.saveCycle(MonthlyCycle.empty('2026-09'));

        final result = await gateway.listClosedCycleSnapshots();

        final snapshots = result.getOrElse(
          (_) => throw StateError('expected Right'),
        );
        expect(snapshots, hasLength(1));
        expect(snapshots.single.cycleId, '2026-08');
        expect(snapshots.single.isClosed, isTrue);
      },
    );
  });
}
