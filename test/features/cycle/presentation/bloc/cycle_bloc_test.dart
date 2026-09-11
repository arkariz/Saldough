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
import 'package:saldough/features/cycle/domain/repositories/card_catalog.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_template_repository.dart';
import 'package:saldough/features/cycle/domain/usecases/roll_over_cycle.dart';
import 'package:saldough/features/cycle/presentation/bloc/cycle_bloc.dart';
import 'package:saldough/features/cycle/presentation/bloc/cycle_state.dart';
import 'package:saldough/shared/income/income.dart';
import 'package:state_management/state_management.dart';

class MockCycleRepository extends Mock implements CycleRepository {}

class MockCycleTemplateRepository extends Mock
    implements CycleTemplateRepository {}

class MockIncomeSourceRepository extends Mock
    implements IncomeSourceRepository {}

class MockCardCatalog extends Mock implements CardCatalog {}

void main() {
  late MockCycleRepository cycleRepository;
  late MockCycleTemplateRepository templateRepository;
  late MockIncomeSourceRepository sourceRepository;
  late MockCardCatalog cardCatalog;

  setUpAll(() {
    registerFallbackValue(MonthlyCycle.empty('2026-09'));
  });

  setUp(() {
    cycleRepository = MockCycleRepository();
    templateRepository = MockCycleTemplateRepository();
    sourceRepository = MockIncomeSourceRepository();
    cardCatalog = MockCardCatalog();
    when(
      () => sourceRepository.listSources(),
    ).thenAnswer((_) async => right(const []));
    when(
      () => cycleRepository.listCycleIds(),
    ).thenAnswer((_) async => right(const []));
    when(
      () => cardCatalog.listCards(),
    ).thenAnswer((_) async => right(const []));
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
    sourceRepository: sourceRepository,
    cardCatalog: cardCatalog,
  );

  final cycleWithLines = MonthlyCycle(
    id: '2026-09',
    incomeLines: const [
      IncomeLine(id: 'i1', label: 'Gaji', amount: 1583956300),
    ],
    budgetLines: [
      BudgetLine(
        id: 'b1',
        label: 'Kos',
        amount: 1338249000,
        kind: BudgetLineKind.manual,
      ),
    ],
    investmentPlan: InvestmentPlan.empty(),
  );

  group('CycleBloc', () {
    blocTest<CycleBloc, CycleState>(
      'CycleOpened memuat siklus dan menghitung total/sisa',
      build: () {
        when(
          () => cycleRepository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(cycleWithLines));
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
      'CycleOpened memuat daftar id siklus yang benar-benar ada, untuk membatasi navigasi',
      build: () {
        when(
          () => cycleRepository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(cycleWithLines));
        when(
          () => cycleRepository.listCycleIds(),
        ).thenAnswer((_) async => right(const ['2026-08', '2026-09']));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CycleOpened('2026-09')),
      expect: () => [
        isA<CycleState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CycleState>()
            .having((s) => s.hasCycle('2026-08'), 'hasCycle(2026-08)', isTrue)
            .having((s) => s.hasCycle('2026-10'), 'hasCycle(2026-10)', isFalse),
      ],
    );

    blocTest<CycleBloc, CycleState>(
      'CycleOpened untuk siklus yang belum ada menampilkan siklus kosong, bukan galat',
      build: () {
        when(
          () => cycleRepository.getCycle('2026-11'),
        ).thenAnswer((_) async => right(null));
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
        when(
          () => cycleRepository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(cycleWithLines));
        when(
          () => cycleRepository.saveCycle(any()),
        ).thenAnswer((_) async => right(unit));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IncomeLineSaved(label: 'Bonus', amount: 50000000));
      },
      skip: 2,
      expect: () => [
        isA<CycleState>().having(
          (s) => s.cycle.incomeLines,
          'incomeLines',
          hasLength(2),
        ),
      ],
      verify: (_) => verify(() => cycleRepository.saveCycle(any())).called(1),
    );

    blocTest<CycleBloc, CycleState>(
      'CycleOpened memuat daftar kartu dari CardCatalog ke state.cards',
      build: () {
        when(
          () => cycleRepository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(cycleWithLines));
        when(() => cardCatalog.listCards()).thenAnswer(
          (_) async => right(const [CardSummary(id: 'c1', name: 'CC TOKPED')]),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CycleOpened('2026-09')),
      skip: 1,
      expect: () => [
        isA<CycleState>().having((s) => s.cards, 'cards', const [
          CardSummary(id: 'c1', name: 'CC TOKPED'),
        ]),
      ],
    );

    blocTest<CycleBloc, CycleState>(
      'BudgetLineSaved dengan rollUpSource menautkan baris baru ke Rencana '
      'Belanja, lalu menyegarkan nominalnya dari getCycle',
      build: () {
        final resolvedCycle = MonthlyCycle(
          id: '2026-09',
          incomeLines: cycleWithLines.incomeLines,
          budgetLines: [
            ...cycleWithLines.budgetLines,
            BudgetLine(
              id: 'g1',
              label: 'Rencana Belanja',
              amount: 123456,
              kind: BudgetLineKind.rollUp,
              rollUpSource: RollUpSource.grocery,
            ),
          ],
          investmentPlan: InvestmentPlan.empty(),
        );
        var callCount = 0;
        when(() => cycleRepository.getCycle('2026-09')).thenAnswer((_) async {
          callCount++;
          return right(callCount == 1 ? cycleWithLines : resolvedCycle);
        });
        when(
          () => cycleRepository.saveCycle(any()),
        ).thenAnswer((_) async => right(unit));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const BudgetLineSaved(
            label: 'Rencana Belanja',
            amount: 0,
            rollUpSource: RollUpSource.grocery,
          ),
        );
      },
      skip: 2,
      expect: () => [
        isA<CycleState>()
            .having(
              (s) => s.cycle.budgetLines.last.kind,
              'kind baris baru',
              BudgetLineKind.rollUp,
            )
            .having(
              (s) => s.cycle.budgetLines.last.amount,
              'amount sebelum disegarkan',
              0,
            ),
        isA<CycleState>().having(
          (s) => s.cycle.budgetLines.last.amount,
          'amount setelah disegarkan',
          123456,
        ),
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
        when(
          () => cycleRepository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(cycleWithRollUp));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const BudgetLineSaved(id: 'r1', label: 'Bulanan', amount: 999),
        );
      },
      skip: 2,
      expect: () => [
        isA<CycleState>().having(
          (s) => s.effect,
          'effect',
          isA<ShowSnackBarEffect>(),
        ),
      ],
      verify: (_) => verifyNever(() => cycleRepository.saveCycle(any())),
    );

    blocTest<CycleBloc, CycleState>(
      'Penyuntingan ditolak kalau siklus sudah ditutup',
      build: () {
        final closed = cycleWithLines.close();
        when(
          () => cycleRepository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(closed));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IncomeLineSaved(label: 'Bonus', amount: 1));
      },
      skip: 2,
      expect: () => [
        isA<CycleState>().having(
          (s) => s.effect,
          'effect',
          isA<ShowSnackBarEffect>(),
        ),
      ],
      verify: (_) => verifyNever(() => cycleRepository.saveCycle(any())),
    );

    blocTest<CycleBloc, CycleState>(
      'CycleReopened membuka kembali siklus yang ditutup',
      build: () {
        final closed = cycleWithLines.close();
        when(
          () => cycleRepository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(closed));
        when(
          () => cycleRepository.saveCycle(any()),
        ).thenAnswer((_) async => right(unit));
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
      'CycleRollOverRequested berpindah ke siklus baru hasil rollover, dan mendaftarkannya '
      'ke existingCycleIds supaya bisa dinavigasi',
      build: () {
        when(
          () => cycleRepository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(cycleWithLines));
        when(
          () => cycleRepository.getCycle('2026-10'),
        ).thenAnswer((_) async => right(null));
        when(
          () => cycleRepository.listCycleIds(),
        ).thenAnswer((_) async => right(const ['2026-09']));
        when(
          () => templateRepository.getTemplate(),
        ).thenAnswer((_) async => right(CycleTemplate.empty()));
        when(() => cycleRepository.saveCycle(any())).thenAnswer((
          invocation,
        ) async {
          final saved = invocation.positionalArguments.first as MonthlyCycle;
          when(
            () => cycleRepository.listCycleIds(),
          ).thenAnswer((_) async => right(['2026-09', saved.id]));
          return right(unit);
        });
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
            .having((s) => s.hasCycle('2026-10'), 'hasCycle(2026-10)', isTrue)
            .having((s) => s.effect, 'effect', isA<ShowSnackBarEffect>()),
      ],
    );

    blocTest<CycleBloc, CycleState>(
      'CycleDeleteRequested menghapus siklus terakhir lalu berpindah ke siklus sebelumnya',
      build: () {
        when(
          () => cycleRepository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(cycleWithLines));
        when(
          () => cycleRepository.getCycle('2026-08'),
        ).thenAnswer((_) async => right(null));
        when(
          () => cycleRepository.listCycleIds(),
        ).thenAnswer((_) async => right(const ['2026-08', '2026-09']));
        when(() => cycleRepository.deleteCycle('2026-09')).thenAnswer((
          invocation,
        ) async {
          when(
            () => cycleRepository.listCycleIds(),
          ).thenAnswer((_) async => right(const ['2026-08']));
          return right(unit);
        });
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CycleDeleteRequested());
      },
      skip: 2,
      expect: () => [
        isA<CycleState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CycleState>()
            .having((s) => s.cycle.id, 'cycle.id', '2026-08')
            .having((s) => s.hasCycle('2026-09'), 'hasCycle(2026-09)', isFalse),
      ],
      verify: (_) =>
          verify(() => cycleRepository.deleteCycle('2026-09')).called(1),
    );

    blocTest<CycleBloc, CycleState>(
      'CycleDeleteRequested diabaikan kalau bukan siklus terakhir (canDeleteCycle false)',
      build: () {
        when(
          () => cycleRepository.getCycle('2026-08'),
        ).thenAnswer((_) async => right(MonthlyCycle.empty('2026-08')));
        when(
          () => cycleRepository.listCycleIds(),
        ).thenAnswer((_) async => right(const ['2026-08', '2026-09']));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-08'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CycleDeleteRequested());
      },
      skip: 2,
      expect: () => <CycleState>[],
      verify: (_) => verifyNever(() => cycleRepository.deleteCycle(any())),
    );

    blocTest<CycleBloc, CycleState>(
      'CycleDeleteRequested diabaikan kalau siklus sudah ditutup',
      build: () {
        final closed = cycleWithLines.close();
        when(
          () => cycleRepository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(closed));
        when(
          () => cycleRepository.listCycleIds(),
        ).thenAnswer((_) async => right(const ['2026-09']));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CycleDeleteRequested());
      },
      skip: 2,
      expect: () => <CycleState>[],
      verify: (_) => verifyNever(() => cycleRepository.deleteCycle(any())),
    );
  });
}
