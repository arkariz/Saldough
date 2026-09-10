import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/cycle/domain/entities/allocation.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line_kind.dart';
import 'package:saldough/features/cycle/domain/entities/cycle_template.dart';
import 'package:saldough/features/cycle/domain/entities/income_line.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_template_repository.dart';
import 'package:saldough/features/cycle/domain/usecases/roll_over_cycle.dart';

class MockCycleRepository extends Mock implements CycleRepository {}

class MockCycleTemplateRepository extends Mock implements CycleTemplateRepository {}

void main() {
  late MockCycleRepository cycleRepository;
  late MockCycleTemplateRepository templateRepository;
  late RollOverCycle rollOver;

  setUpAll(() {
    registerFallbackValue(MonthlyCycle.empty('2026-10'));
  });

  setUp(() {
    cycleRepository = MockCycleRepository();
    templateRepository = MockCycleTemplateRepository();
    rollOver = RollOverCycle(
      cycleRepository: cycleRepository,
      templateRepository: templateRepository,
    );
  });

  group('RollOverCycle', () {
    test('membuat siklus bulan berikutnya dari template', () async {
      when(() => cycleRepository.getCycle('2026-10')).thenAnswer((_) async => right(null));
      when(() => templateRepository.getTemplate()).thenAnswer(
        (_) async => right(CycleTemplate(
          incomeLines: const [
            IncomeLine(id: 'tmpl-income', label: 'Gaji', amount: 300000000, isTemplate: true),
          ],
          budgetLines: [
            BudgetLine(
              id: 'tmpl-budget-manual',
              label: 'Kos',
              amount: 150000000,
              kind: BudgetLineKind.manual,
              isTemplate: true,
            ),
            BudgetLine(
              id: 'tmpl-budget-rollup',
              label: 'Bulanan',
              amount: 99999999, // nilai lama — harus TIDAK disalin
              kind: BudgetLineKind.rollUp,
              rollUpSource: RollUpSource.grocery,
              isTemplate: true,
            ),
          ],
          defaultAllocations: const [Allocation(goalId: 'kyoto', percentage: 20)],
        )),
      );
      when(() => cycleRepository.saveCycle(any())).thenAnswer((_) async => right(unit));

      final result = await rollOver('2026-09');

      final cycle = result.getOrElse((_) => throw StateError('expected Right'));
      expect(cycle.id, '2026-10');

      expect(cycle.incomeLines, hasLength(1));
      expect(cycle.incomeLines.single.amount, 300000000);
      expect(cycle.incomeLines.single.isTemplate, isTrue);
      expect(cycle.incomeLines.single.needsReview, isTrue);

      expect(cycle.budgetLines, hasLength(2));
      final manual = cycle.budgetLines.firstWhere((l) => l.kind == BudgetLineKind.manual);
      expect(manual.amount, 150000000);
      expect(manual.needsReview, isTrue);

      final rollUp = cycle.budgetLines.firstWhere((l) => l.kind == BudgetLineKind.rollUp);
      expect(rollUp.amount, 0, reason: 'nominal roll-up lama tidak boleh ikut disalin (ADR-0008)');
      expect(rollUp.needsReview, isTrue);
      expect(rollUp.rollUpSource, RollUpSource.grocery);

      expect(cycle.investmentPlan.allocations, [const Allocation(goalId: 'kyoto', percentage: 20)]);
      expect(cycle.investmentPlan.returnDeposit, 0);

      verify(() => cycleRepository.saveCycle(any())).called(1);
    });

    test('menolak rollover kalau siklus bulan berikutnya sudah ada', () async {
      when(() => cycleRepository.getCycle('2026-10')).thenAnswer(
        (_) async => right(MonthlyCycle.empty('2026-10')),
      );

      final result = await rollOver('2026-09');

      expect(result, isA<Left<Failure, dynamic>>());
      verifyNever(() => templateRepository.getTemplate());
      verifyNever(() => cycleRepository.saveCycle(any()));
    });

    test('Desember berpindah ke Januari tahun berikutnya', () async {
      when(() => cycleRepository.getCycle('2027-01')).thenAnswer((_) async => right(null));
      when(() => templateRepository.getTemplate()).thenAnswer(
        (_) async => right(CycleTemplate.empty()),
      );
      when(() => cycleRepository.saveCycle(any())).thenAnswer((_) async => right(unit));

      final result = await rollOver('2026-12');

      final cycle = result.getOrElse((_) => throw StateError('expected Right'));
      expect(cycle.id, '2027-01');
    });
  });
}
