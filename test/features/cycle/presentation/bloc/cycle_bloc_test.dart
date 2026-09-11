import 'package:bloc_test/bloc_test.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
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
    registerFallbackValue(CycleTemplate.empty());
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
      'CycleOpened yang gagal menghasilkan state bertanda galat, bukan state siklus kosong',
      build: () {
        when(() => cycleRepository.getCycle('2026-09')).thenAnswer(
          (_) async => left(
            const BusinessRuleFailure(
              code: FailureCode('STORAGE_ERROR'),
              message: 'gagal baca',
              userMessage: 'Gagal memuat siklus.',
            ),
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CycleOpened('2026-09')),
      expect: () => [
        isA<CycleState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CycleState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.hasLoadError, 'hasLoadError', isTrue)
            // UX-16: berbeda dari siklus kosong -- ini kegagalan, bukan
            // "belum ada baris". cycle.id TIDAK ikut jadi '2026-09' karena
            // Left tidak pernah menyentuh cycle di state (lihat juga BUG-1).
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
      'BudgetLineSaved dengan rollUpSource yang sudah dipakai baris lain '
      'ditolak dengan efek peringatan, tanpa menyimpan',
      build: () {
        final cycleWithGroceryRollUp = MonthlyCycle(
          id: '2026-09',
          incomeLines: const [],
          budgetLines: [
            BudgetLine(
              id: 'g1',
              label: 'Rencana Belanja',
              amount: 500000,
              kind: BudgetLineKind.rollUp,
              rollUpSource: RollUpSource.grocery,
            ),
          ],
          investmentPlan: InvestmentPlan.empty(),
        );
        when(
          () => cycleRepository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(cycleWithGroceryRollUp));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const BudgetLineSaved(
            label: 'Rencana Belanja (dobel)',
            amount: 0,
            rollUpSource: RollUpSource.grocery,
          ),
        );
      },
      skip: 2,
      expect: () => [
        isA<CycleState>()
            .having(
              (s) => s.effect,
              'effect',
              isA<ShowSnackBarEffect>(),
            )
            .having(
              (s) => s.cycle.budgetLines,
              'budgetLines tidak bertambah',
              hasLength(1),
            ),
      ],
      verify: (_) => verifyNever(() => cycleRepository.saveCycle(any())),
    );

    // UX-37: pemilik bisa mengganti nama baris rollUp sendiri -- ADR-0008
    // hanya mengunci nominal, tidak pernah mengunci label.
    blocTest<CycleBloc, CycleState>(
      'BudgetLineRenamed mengganti nama baris rollUp tanpa menyentuh nominal/sumbernya',
      build: () {
        final cycleWithGroceryRollUp = MonthlyCycle(
          id: '2026-09',
          incomeLines: const [],
          budgetLines: [
            BudgetLine(
              id: 'g1',
              label: 'Rencana Belanja',
              amount: 500000,
              kind: BudgetLineKind.rollUp,
              rollUpSource: RollUpSource.grocery,
            ),
          ],
          investmentPlan: InvestmentPlan.empty(),
        );
        when(
          () => cycleRepository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(cycleWithGroceryRollUp));
        when(
          () => cycleRepository.saveCycle(any()),
        ).thenAnswer((_) async => right(unit));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BudgetLineRenamed(lineId: 'g1', label: 'Belanja bulanan'));
      },
      skip: 2,
      expect: () => [
        isA<CycleState>()
            .having((s) => s.cycle.budgetLines.single.label, 'label', 'Belanja bulanan')
            .having((s) => s.cycle.budgetLines.single.amount, 'amount', 500000)
            .having((s) => s.cycle.budgetLines.single.kind, 'kind', BudgetLineKind.rollUp)
            .having(
              (s) => s.cycle.budgetLines.single.rollUpSource,
              'rollUpSource',
              RollUpSource.grocery,
            ),
      ],
      verify: (_) => verify(() => cycleRepository.saveCycle(any())).called(1),
    );

    blocTest<CycleBloc, CycleState>(
      'BudgetLineSaved tetap bisa menautkan kartu berbeda meski kartu lain '
      'sudah dipakai baris rollUp lain',
      build: () {
        final cycleWithCardRollUp = MonthlyCycle(
          id: '2026-09',
          incomeLines: const [],
          budgetLines: [
            BudgetLine(
              id: 'c1',
              label: 'CC TOKPED',
              amount: 300000,
              kind: BudgetLineKind.rollUp,
              rollUpSource: RollUpSource.card('cardA'),
            ),
          ],
          investmentPlan: InvestmentPlan.empty(),
        );
        final resolvedCycle = MonthlyCycle(
          id: '2026-09',
          incomeLines: const [],
          budgetLines: [
            ...cycleWithCardRollUp.budgetLines,
            BudgetLine(
              id: 'c2',
              label: 'CC BRI',
              amount: 654321,
              kind: BudgetLineKind.rollUp,
              rollUpSource: RollUpSource.card('cardB'),
            ),
          ],
          investmentPlan: InvestmentPlan.empty(),
        );
        var callCount = 0;
        when(() => cycleRepository.getCycle('2026-09')).thenAnswer((_) async {
          callCount++;
          return right(callCount == 1 ? cycleWithCardRollUp : resolvedCycle);
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
          BudgetLineSaved(
            label: 'CC BRI',
            amount: 0,
            rollUpSource: RollUpSource.card('cardB'),
          ),
        );
      },
      skip: 2,
      expect: () => [
        isA<CycleState>().having(
          (s) => s.cycle.budgetLines,
          'budgetLines sebelum disegarkan',
          hasLength(2),
        ),
        isA<CycleState>().having(
          (s) => s.cycle.budgetLines.last.amount,
          'amount setelah disegarkan',
          654321,
        ),
      ],
      verify: (_) => verify(() => cycleRepository.saveCycle(any())).called(1),
    );

    blocTest<CycleBloc, CycleState>(
      'CycleIncomeSourcesRefreshRequested menyegarkan incomeSources saja, '
      'tanpa memuat ulang siklus (laporan pemilik: sumber baru dari layar '
      'tambah sumber tidak terdeteksi tanpa pindah tab)',
      build: () {
        when(
          () => cycleRepository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(cycleWithLines));
        var callCount = 0;
        when(() => sourceRepository.listSources()).thenAnswer((_) async {
          callCount++;
          return right(
            callCount == 1
                ? const []
                : [
                    IncomeSource(
                      id: 's1',
                      name: 'Gaji Tetap',
                      kind: IncomeSourceKind.fixedSalary,
                      fixedAmount: 1000000,
                    ),
                  ],
          );
        });
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CycleIncomeSourcesRefreshRequested());
      },
      skip: 2,
      expect: () => [
        isA<CycleState>()
            .having(
              (s) => s.incomeSources,
              'incomeSources',
              hasLength(1),
            )
            .having((s) => s.cycle.id, 'cycle.id tidak berubah', '2026-09'),
      ],
      verify: (_) =>
          verify(() => cycleRepository.getCycle('2026-09')).called(1),
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
            .having(
              (s) => (s.effect! as ShowSnackBarEffect).message,
              'effect.message',
              // UX-14: bukan lagi id siklus mentah ("2026-10") -- kalimat
              // lewat slang dengan nama bulan yang diformat.
              'Siklus Oktober 2026 sudah dibuat.',
            ),
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

    // UX-06: sebelumnya hasil saveTemplate() dibuang begitu saja -- pin
    // "tetap" tampak berhasil di layar padahal tidak ikut terbawa saat
    // rollover, tanpa pemilik pernah tahu.
    blocTest<CycleBloc, CycleState>(
      'IncomeLineTemplateToggled memancarkan efek galat dan TIDAK menandai '
      'baris kalau penulisan template gagal',
      build: () {
        when(
          () => cycleRepository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(cycleWithLines));
        when(
          () => templateRepository.getTemplate(),
        ).thenAnswer((_) async => right(CycleTemplate.empty()));
        when(
          () => templateRepository.saveTemplate(any()),
        ).thenAnswer(
          (_) async => left(
            const PersistenceFailure(
              code: FailureCode('STORAGE_ERROR'),
              message: 'disk penuh',
              userMessage: 'Gagal menyimpan.',
            ),
          ),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IncomeLineTemplateToggled('i1'));
      },
      skip: 2,
      expect: () => [
        isA<CycleState>()
            .having((s) => s.effect, 'effect', isA<ShowSnackBarEffect>())
            .having(
              (s) => s.findIncomeLine('i1')?.isTemplate,
              'baris i1 tetap tidak ditandai',
              false,
            ),
      ],
      verify: (_) => verifyNever(() => cycleRepository.saveCycle(any())),
    );

    blocTest<CycleBloc, CycleState>(
      'BudgetLineTemplateToggled memancarkan efek galat dan TIDAK menandai '
      'baris kalau penulisan template gagal',
      build: () {
        when(
          () => cycleRepository.getCycle('2026-09'),
        ).thenAnswer((_) async => right(cycleWithLines));
        when(
          () => templateRepository.getTemplate(),
        ).thenAnswer((_) async => right(CycleTemplate.empty()));
        when(
          () => templateRepository.saveTemplate(any()),
        ).thenAnswer(
          (_) async => left(
            const PersistenceFailure(
              code: FailureCode('STORAGE_ERROR'),
              message: 'disk penuh',
              userMessage: 'Gagal menyimpan.',
            ),
          ),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const CycleOpened('2026-09'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BudgetLineTemplateToggled('b1'));
      },
      skip: 2,
      expect: () => [
        isA<CycleState>()
            .having((s) => s.effect, 'effect', isA<ShowSnackBarEffect>())
            .having(
              (s) => s.findBudgetLine('b1')?.isTemplate,
              'baris b1 tetap tidak ditandai',
              false,
            ),
      ],
      verify: (_) => verifyNever(() => cycleRepository.saveCycle(any())),
    );
  });
}
