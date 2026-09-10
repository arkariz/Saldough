import 'package:bloc_test/bloc_test.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line_kind.dart';
import 'package:saldough/features/cycle/domain/entities/cycle_template.dart';
import 'package:saldough/features/cycle/domain/entities/income_line.dart';
import 'package:saldough/features/cycle/domain/entities/investment_plan.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_template_repository.dart';
import 'package:saldough/features/cycle/domain/usecases/roll_over_cycle.dart';
import 'package:saldough/features/cycle/presentation/bloc/cycle_bloc.dart';
import 'package:saldough/features/cycle/presentation/bloc/cycle_state.dart';
import 'package:state_management/state_management.dart';

class MockCycleRepository extends Mock implements CycleRepository {}

class MockCycleTemplateRepository extends Mock implements CycleTemplateRepository {}

void main() {
  late MockCycleRepository cycleRepository;
  late MockCycleTemplateRepository templateRepository;

  setUpAll(() {
    registerFallbackValue(MonthlyCycle.empty('2026-09'));
  });

  setUp(() {
    cycleRepository = MockCycleRepository();
    templateRepository = MockCycleTemplateRepository();
  });

  // RollOverCycle sendiri final class (tidak bisa di-mock mocktail) dan
  // sudah diuji terpisah di roll_over_cycle_test.dart — di sini dipakai
  // instance sungguhan di atas repository yang sama-sama dipalsukan.
  CycleBloc buildBloc() => CycleBloc(
        cycleRepository: cycleRepository,
        templateRepository: templateRepository,
        rollOverCycle: RollOverCycle(
          cycleRepository: cycleRepository,
          templateRepository: templateRepository,
        ),
      );

  final cycleWithLines = MonthlyCycle(
    id: '2026-09',
    incomeLines: const [IncomeLine(id: 'i1', label: 'Gaji', amount: 1583956300)],
    budgetLines: [
      BudgetLine(id: 'b1', label: 'Kos', amount: 1338249000, kind: BudgetLineKind.manual),
    ],
    investmentPlan: InvestmentPlan.empty(),
  );

  group('CycleBloc', () {
    blocTest<CycleBloc, CycleState>(
      'CycleOpened memuat siklus dan menghitung total/sisa',
      build: () {
        when(() => cycleRepository.getCycle('2026-09')).thenAnswer((_) async => right(cycleWithLines));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CycleOpened('2026-09')),
      expect: () => [
        isA<CycleState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CycleState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.totals.totalIncome, 'totalIncome', 1583956300)
            .having((s) => s.totals.remainder, 'remainder', 245707300),
      ],
    );

    blocTest<CycleBloc, CycleState>(
      'CycleOpened untuk siklus yang belum ada menampilkan siklus kosong, bukan galat',
      build: () {
        when(() => cycleRepository.getCycle('2026-11')).thenAnswer((_) async => right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CycleOpened('2026-11')),
      expect: () => [
        isA<CycleState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CycleState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.cycle.id, 'cycle.id', '2026-11')
            .having((s) => s.cycle.incomeLines, 'incomeLines', isEmpty),
      ],
    );

    blocTest<CycleBloc, CycleState>(
      'IncomeLineSaved menambah baris baru lalu menyimpan',
      build: () {
        when(() => cycleRepository.getCycle('2026-09')).thenAnswer((_) async => right(cycleWithLines));
        when(() => cycleRepository.saveCycle(any())).thenAnswer((_) async => right(unit));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IncomeLineSaved(label: 'Bonus', amount: 50000000));
      },
      skip: 2,
      expect: () => [
        isA<CycleState>().having((s) => s.cycle.incomeLines, 'incomeLines', hasLength(2)),
      ],
      verify: (_) => verify(() => cycleRepository.saveCycle(any())).called(1),
    );

    blocTest<CycleBloc, CycleState>(
      'BudgetLineSaved pada baris rollUp ditolak dengan efek peringatan',
      build: () {
        final cycleWithRollUp = MonthlyCycle(
          id: '2026-09',
          incomeLines: const [],
          budgetLines: [
            BudgetLine(
              id: 'r1',
              label: 'Bulanan',
              amount: 0,
              kind: BudgetLineKind.rollUp,
              rollUpSource: RollUpSource.grocery,
            ),
          ],
          investmentPlan: InvestmentPlan.empty(),
        );
        when(() => cycleRepository.getCycle('2026-09')).thenAnswer((_) async => right(cycleWithRollUp));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BudgetLineSaved(id: 'r1', label: 'Bulanan', amount: 999));
      },
      skip: 2,
      expect: () => [
        isA<CycleState>().having((s) => s.effect, 'effect', isA<ShowSnackBarEffect>()),
      ],
      verify: (_) => verifyNever(() => cycleRepository.saveCycle(any())),
    );

    blocTest<CycleBloc, CycleState>(
      'Penyuntingan ditolak kalau siklus sudah ditutup',
      build: () {
        final closed = cycleWithLines.close();
        when(() => cycleRepository.getCycle('2026-09')).thenAnswer((_) async => right(closed));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IncomeLineSaved(label: 'Bonus', amount: 1));
      },
      skip: 2,
      expect: () => [
        isA<CycleState>().having((s) => s.effect, 'effect', isA<ShowSnackBarEffect>()),
      ],
      verify: (_) => verifyNever(() => cycleRepository.saveCycle(any())),
    );

    blocTest<CycleBloc, CycleState>(
      'CycleReopened membuka kembali siklus yang ditutup',
      build: () {
        final closed = cycleWithLines.close();
        when(() => cycleRepository.getCycle('2026-09')).thenAnswer((_) async => right(closed));
        when(() => cycleRepository.saveCycle(any())).thenAnswer((_) async => right(unit));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CycleReopened());
      },
      skip: 2,
      expect: () => [
        isA<CycleState>().having((s) => s.cycle.isClosed, 'isClosed', isFalse),
      ],
    );

    blocTest<CycleBloc, CycleState>(
      'CycleRollOverRequested berpindah ke siklus baru hasil rollover',
      build: () {
        when(() => cycleRepository.getCycle('2026-09')).thenAnswer((_) async => right(cycleWithLines));
        when(() => cycleRepository.getCycle('2026-10')).thenAnswer((_) async => right(null));
        when(() => templateRepository.getTemplate())
            .thenAnswer((_) async => right(CycleTemplate.empty()));
        when(() => cycleRepository.saveCycle(any())).thenAnswer((_) async => right(unit));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CycleRollOverRequested());
      },
      skip: 2,
      expect: () => [
        isA<CycleState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CycleState>()
            .having((s) => s.cycle.id, 'cycle.id', '2026-10')
            .having((s) => s.effect, 'effect', isA<ShowSnackBarEffect>()),
      ],
    );
  });
}
