import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/cycle/data/adapters/cycle_income_writer_impl.dart';
import 'package:saldough/features/cycle/domain/entities/income_line.dart';
import 'package:saldough/features/cycle/domain/entities/investment_plan.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_repository.dart';

class MockCycleRepository extends Mock implements CycleRepository {}

void main() {
  late MockCycleRepository repository;

  setUpAll(() {
    registerFallbackValue(MonthlyCycle.empty('2026-09'));
  });

  setUp(() {
    repository = MockCycleRepository();
    when(
      () => repository.saveCycle(any()),
    ).thenAnswer((_) async => right(unit));
  });

  group('CycleIncomeWriterImpl', () {
    test(
      'membuat baris pemasukan baru kalau belum ada baris ber-sourceId itu',
      () async {
        when(
          () => repository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(MonthlyCycle.empty('2026-09')));
        final writer = CycleIncomeWriterImpl(cycleRepository: repository);

        final result = await writer.inject(
          cycleId: '2026-09',
          sourceId: 'gaji-menul',
          sourceLabel: 'Gaji Menul',
          amount: 303956250,
        );

        expect(result.isRight(), isTrue);
        final saved =
            verify(() => repository.saveCycle(captureAny())).captured.single
                as MonthlyCycle;
        expect(saved.incomeLines, hasLength(1));
        expect(saved.incomeLines.single.sourceId, 'gaji-menul');
        expect(saved.incomeLines.single.amount, 303956250);
      },
    );

    test(
      'menimpa baris pemasukan yang sudah ada untuk sourceId yang sama',
      () async {
        final cycle = MonthlyCycle(
          id: '2026-09',
          incomeLines: const [
            IncomeLine(
              id: 'existing',
              label: 'Gaji Menul',
              amount: 1,
              sourceId: 'gaji-menul',
            ),
          ],
          budgetLines: const [],
          investmentPlan: InvestmentPlan.empty(),
        );
        when(
          () => repository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(cycle));
        final writer = CycleIncomeWriterImpl(cycleRepository: repository);

        final result = await writer.inject(
          cycleId: '2026-09',
          sourceId: 'gaji-menul',
          sourceLabel: 'Gaji Menul',
          amount: 303956250,
        );

        expect(result.getOrElse((_) => ''), 'existing');
        final saved =
            verify(() => repository.saveCycle(captureAny())).captured.single
                as MonthlyCycle;
        expect(saved.incomeLines, hasLength(1));
        expect(saved.incomeLines.single.amount, 303956250);
      },
    );

    test('menolak menyuntik ke siklus yang belum ada', () async {
      when(
        () => repository.getCycle('2026-12'),
      ).thenAnswer((_) async => right(null));
      final writer = CycleIncomeWriterImpl(cycleRepository: repository);

      final result = await writer.inject(
        cycleId: '2026-12',
        sourceId: 'gaji-menul',
        sourceLabel: 'Gaji Menul',
        amount: 1,
      );

      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.saveCycle(any()));
    });

    test('menolak menyuntik ke siklus yang sudah ditutup', () async {
      final closed = MonthlyCycle.empty('2026-09').close();
      when(
        () => repository.getCycle('2026-09'),
      ).thenAnswer((_) async => right(closed));
      final writer = CycleIncomeWriterImpl(cycleRepository: repository);

      final result = await writer.inject(
        cycleId: '2026-09',
        sourceId: 'gaji-menul',
        sourceLabel: 'Gaji Menul',
        amount: 1,
      );

      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.saveCycle(any()));
    });
  });
}
