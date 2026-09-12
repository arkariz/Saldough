import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/cycle/data/repositories/cycle_repository_impl.dart';
import 'package:saldough/features/cycle/data/roll_up/unavailable_roll_up_resolver.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line_kind.dart';
import 'package:saldough/features/cycle/domain/entities/income_line.dart';
import 'package:saldough/features/cycle/domain/entities/investment_plan.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_resolution.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';
import 'package:saldough/features/cycle/domain/repositories/roll_up_resolver.dart';
import 'package:saldough/shared/income/income.dart';

/// Resolver palsu yang menghitung berapa kali [resolve] dipanggil — dipakai
/// membuktikan T-4.12: siklus tertutup tidak pernah memanggil resolver lagi.
class _CountingResolver implements RollUpResolver {
  int calls = 0;

  @override
  Future<RollUpResolution> resolve(RollUpSource source) async {
    calls++;
    return const RollUpResolution(amount: 999999, isAvailable: true);
  }
}

void main() {
  late InMemoryKeyValueStorage storage;
  late CycleRepositoryImpl repository;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = CycleRepositoryImpl(
      storage: storage,
      resolver: const UnavailableRollUpResolver(),
      incomeSourceRepository: IncomeSourceRepositoryImpl(storage: storage),
    );
  });

  group('CycleRepositoryImpl', () {
    test(
      'menyimpan lalu membaca siklus mengembalikan nilai yang sama untuk baris manual',
      () async {
        final cycle = MonthlyCycle(
          id: '2026-09',
          incomeLines: const [
            IncomeLine(id: 'i1', label: 'Gaji', amount: 300000000),
          ],
          budgetLines: [
            BudgetLine(
              id: 'b1',
              label: 'Kos',
              amount: 150000000,
              kind: BudgetLineKind.manual,
            ),
          ],
          investmentPlan: InvestmentPlan.empty(),
        );

        final saveResult = await repository.saveCycle(cycle);
        expect(saveResult.isRight(), isTrue);

        final readResult = await repository.getCycle('2026-09');
        final read = readResult.getOrElse(
          (_) => throw StateError('expected Right'),
        );

        expect(read, isNotNull);
        expect(read!.incomeLines.single.amount, 300000000);
        expect(read.budgetLines.single.amount, 150000000);
      },
    );

    test(
      'baris rollUp selalu bernilai 0 dengan penanda tidak tersedia (UnavailableRollUpResolver)',
      () async {
        final cycle = MonthlyCycle(
          id: '2026-09',
          incomeLines: const [],
          budgetLines: [
            BudgetLine(
              id: 'b1',
              label: 'Bulanan',
              amount: 99999999, // nilai lama, harus diabaikan saat dibaca
              kind: BudgetLineKind.rollUp,
              rollUpSource: RollUpSource.grocery('2026-09'),
            ),
          ],
          investmentPlan: InvestmentPlan.empty(),
        );
        await repository.saveCycle(cycle);

        final readResult = await repository.getCycle('2026-09');
        final read = readResult.getOrElse(
          (_) => throw StateError('expected Right'),
        );

        expect(read!.budgetLines.single.amount, 0);
        expect(read.budgetLines.single.rollUpSourceUnavailable, isTrue);
      },
    );

    test(
      'rollUp dibekukan (tidak dihitung ulang) begitu siklus ditutup (T-4.12)',
      () async {
        final resolver = _CountingResolver();
        final closedRepository = CycleRepositoryImpl(
          storage: storage,
          resolver: resolver,
          incomeSourceRepository: IncomeSourceRepositoryImpl(storage: storage),
        );
        final closedCycle = MonthlyCycle(
          id: '2026-08',
          incomeLines: const [],
          budgetLines: [
            BudgetLine(
              id: 'b1',
              label: 'CC TOKPED',
              amount: 123456,
              kind: BudgetLineKind.rollUp,
              rollUpSource: RollUpSource.card('cc1'),
            ),
          ],
          investmentPlan: InvestmentPlan.empty(),
        ).close(at: DateTime(2026, 9, 2));
        await closedRepository.saveCycle(closedCycle);

        final readResult = await closedRepository.getCycle('2026-08');
        final read = readResult.getOrElse(
          (_) => throw StateError('expected Right'),
        );

        expect(read!.budgetLines.single.amount, 123456);
        expect(resolver.calls, 0);
      },
    );

    test(
      'siklus terbuka tetap menghitung ulang rollUp seperti biasa (bukan dibekukan)',
      () async {
        final resolver = _CountingResolver();
        final openRepository = CycleRepositoryImpl(
          storage: storage,
          resolver: resolver,
          incomeSourceRepository: IncomeSourceRepositoryImpl(storage: storage),
        );
        final openCycle = MonthlyCycle(
          id: '2026-09',
          incomeLines: const [],
          budgetLines: [
            BudgetLine(
              id: 'b1',
              label: 'CC TOKPED',
              amount: 1,
              kind: BudgetLineKind.rollUp,
              rollUpSource: RollUpSource.card('cc1'),
            ),
          ],
          investmentPlan: InvestmentPlan.empty(),
        );
        await openRepository.saveCycle(openCycle);

        final readResult = await openRepository.getCycle('2026-09');
        final read = readResult.getOrElse(
          (_) => throw StateError('expected Right'),
        );

        expect(read!.budgetLines.single.amount, 999999);
        expect(resolver.calls, 1);
      },
    );

    test(
      'getCycle mengembalikan Right(null) untuk siklus yang belum ada',
      () async {
        final result = await repository.getCycle('2099-01');
        expect(
          result.getOrElse((_) => throw StateError('expected Right')),
          isNull,
        );
      },
    );

    test('listCycleIds terurut dan tidak mengandung duplikat', () async {
      await repository.saveCycle(MonthlyCycle.empty('2026-10'));
      await repository.saveCycle(MonthlyCycle.empty('2026-09'));
      await repository.saveCycle(
        MonthlyCycle.empty('2026-09'),
      ); // disimpan ulang

      final result = await repository.listCycleIds();
      expect(result.getOrElse((_) => throw StateError('expected Right')), [
        '2026-09',
        '2026-10',
      ]);
    });

    test('deleteCycle menghapus dokumen dan id-nya dari index', () async {
      await repository.saveCycle(MonthlyCycle.empty('2026-09'));
      await repository.saveCycle(MonthlyCycle.empty('2026-10'));

      final deleteResult = await repository.deleteCycle('2026-10');
      expect(deleteResult.isRight(), isTrue);

      final readResult = await repository.getCycle('2026-10');
      expect(
        readResult.getOrElse((_) => throw StateError('expected Right')),
        isNull,
      );

      final idsResult = await repository.listCycleIds();
      expect(idsResult.getOrElse((_) => throw StateError('expected Right')), [
        '2026-09',
      ]);
    });

    test('deleteCycle untuk id yang tidak ada tetap Right (no-op)', () async {
      final result = await repository.deleteCycle('2099-01');
      expect(result.isRight(), isTrue);
    });

    test(
      'baris pemasukan bertaut IncomeSource fixedSalary ikut berubah saat sumber diedit, '
      'selama siklus masih terbuka',
      () async {
        final sourceRepository = IncomeSourceRepositoryImpl(storage: storage);
        await sourceRepository.saveSource(
          IncomeSource(
            id: 's1',
            name: 'Gaji Koko',
            kind: IncomeSourceKind.fixedSalary,
            fixedAmount: 1000000000,
          ),
        );
        await repository.saveCycle(
          MonthlyCycle(
            id: '2026-09',
            incomeLines: const [
              IncomeLine(
                id: 'i1',
                label: 'Gaji Koko',
                amount: 1000000000,
                sourceId: 's1',
              ),
            ],
            budgetLines: const [],
            investmentPlan: InvestmentPlan.empty(),
          ),
        );

        // Sumbernya berubah nama dan nominal SETELAH baris pemasukan disimpan.
        await sourceRepository.saveSource(
          IncomeSource(
            id: 's1',
            name: 'Gaji Koko (naik)',
            kind: IncomeSourceKind.fixedSalary,
            fixedAmount: 1300000000,
          ),
        );

        final readResult = await repository.getCycle('2026-09');
        final read = readResult.getOrElse(
          (_) => throw StateError('expected Right'),
        );

        expect(read!.incomeLines.single.label, 'Gaji Koko (naik)');
        expect(read.incomeLines.single.amount, 1300000000);
      },
    );

    test(
      'baris pemasukan bertaut IncomeSource hourlyFreelance HANYA label yang ikut berubah, '
      'nominal tetap snapshot historis (tidak ikut tarif baru)',
      () async {
        final sourceRepository = IncomeSourceRepositoryImpl(storage: storage);
        await sourceRepository.saveSource(
          IncomeSource(
            id: 's2',
            name: 'Gaji Menul',
            kind: IncomeSourceKind.hourlyFreelance,
            hourlyRate: 7250000,
          ),
        );
        await repository.saveCycle(
          MonthlyCycle(
            id: '2026-09',
            incomeLines: const [
              IncomeLine(
                id: 'i1',
                label: 'Gaji Menul',
                amount: 303956300,
                sourceId: 's2',
              ),
            ],
            budgetLines: const [],
            investmentPlan: InvestmentPlan.empty(),
          ),
        );

        await sourceRepository.saveSource(
          IncomeSource(
            id: 's2',
            name: 'Gaji Menul (rebrand)',
            kind: IncomeSourceKind.hourlyFreelance,
            hourlyRate: 8000000,
          ),
        );

        final readResult = await repository.getCycle('2026-09');
        final read = readResult.getOrElse(
          (_) => throw StateError('expected Right'),
        );

        expect(read!.incomeLines.single.label, 'Gaji Menul (rebrand)');
        expect(read.incomeLines.single.amount, 303956300);
      },
    );

    test(
      'baris pemasukan bertaut IncomeSource TIDAK berubah lagi begitu siklus ditutup',
      () async {
        final sourceRepository = IncomeSourceRepositoryImpl(storage: storage);
        await sourceRepository.saveSource(
          IncomeSource(
            id: 's1',
            name: 'Gaji Koko',
            kind: IncomeSourceKind.fixedSalary,
            fixedAmount: 1000000000,
          ),
        );
        final closedCycle = MonthlyCycle(
          id: '2026-08',
          incomeLines: const [
            IncomeLine(
              id: 'i1',
              label: 'Gaji Koko',
              amount: 1000000000,
              sourceId: 's1',
            ),
          ],
          budgetLines: const [],
          investmentPlan: InvestmentPlan.empty(),
        ).close();
        await repository.saveCycle(closedCycle);

        await sourceRepository.saveSource(
          IncomeSource(
            id: 's1',
            name: 'Gaji Koko (naik)',
            kind: IncomeSourceKind.fixedSalary,
            fixedAmount: 1300000000,
          ),
        );

        final readResult = await repository.getCycle('2026-08');
        final read = readResult.getOrElse(
          (_) => throw StateError('expected Right'),
        );

        expect(read!.incomeLines.single.label, 'Gaji Koko');
        expect(read.incomeLines.single.amount, 1000000000);
      },
    );
  });
}
