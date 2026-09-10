import 'package:bloc_test/bloc_test.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/worklog/domain/entities/billing_book.dart';
import 'package:saldough/features/worklog/domain/entities/work_log_entry.dart';
import 'package:saldough/features/worklog/domain/repositories/cycle_income_writer.dart';
import 'package:saldough/features/worklog/domain/repositories/worklog_repository.dart';
import 'package:saldough/features/worklog/domain/usecases/close_billing_book.dart';
import 'package:saldough/features/worklog/domain/usecases/inject_net_pay.dart';
import 'package:saldough/features/worklog/presentation/bloc/worklog_bloc.dart';
import 'package:saldough/features/worklog/presentation/bloc/worklog_state.dart';
import 'package:saldough/shared/income/income.dart';

class MockIncomeSourceRepository extends Mock implements IncomeSourceRepository {}

class MockWorklogRepository extends Mock implements WorklogRepository {}

class MockCycleIncomeWriter extends Mock implements CycleIncomeWriter {}

void main() {
  late MockIncomeSourceRepository sourceRepository;
  late MockWorklogRepository worklogRepository;
  late MockCycleIncomeWriter writer;

  final source = IncomeSource(
    id: 'gaji-menul',
    name: 'Gaji Menul',
    kind: IncomeSourceKind.hourlyFreelance,
    hourlyRate: 7250000,
    deductionRules: const [
      DeductionRule(id: 'pajak', label: 'Pajak', kind: DeductionKind.percentage, value: 25),
    ],
  );

  setUpAll(() {
    registerFallbackValue(
      BillingBook(id: 'b', sourceId: 's', startDate: DateTime(2026), entries: const []),
    );
    registerFallbackValue(WorkLogEntry(id: 'e', date: DateTime(2026), hours: 1));
  });

  setUp(() {
    sourceRepository = MockIncomeSourceRepository();
    worklogRepository = MockWorklogRepository();
    writer = MockCycleIncomeWriter();
  });

  // CloseBillingBook dan InjectNetPay sendiri final class (tidak bisa
  // di-mock mocktail) dan sudah diuji terpisah di
  // close_billing_book_test.dart/inject_net_pay_test.dart — di sini dipakai
  // instance sungguhan di atas repository/writer yang dipalsukan.
  WorklogBloc buildBloc() => WorklogBloc(
        sourceRepository: sourceRepository,
        worklogRepository: worklogRepository,
        closeBillingBook: CloseBillingBook(repository: worklogRepository),
        injectNetPay: InjectNetPay(writer: writer, repository: worklogRepository),
      );

  // WorklogOpened dengan satu sumber freelance selalu menghasilkan 4 state
  // berurutan: isLoading, sumber dimuat (memicu WorklogSourceSelected),
  // isLoading lagi dari situ, lalu buku dimuat. `skip: 4` di tes lain
  // melompati seluruh urutan bootstrap ini.
  group('WorklogBloc', () {
    blocTest<WorklogBloc, WorklogState>(
      'WorklogOpened memuat sumber freelance dan buku sumber pertama',
      build: () {
        when(() => sourceRepository.listSources()).thenAnswer((_) async => right([source]));
        when(() => worklogRepository.listBooks('gaji-menul')).thenAnswer((_) async => right(const []));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const WorklogOpened()),
      expect: () => [
        isA<WorklogState>().having((s) => s.isLoading, 'isLoading', true),
        isA<WorklogState>().having((s) => s.sourceId, 'sourceId', 'gaji-menul'),
        isA<WorklogState>().having((s) => s.isLoading, 'isLoading', true),
        isA<WorklogState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.books, 'books', isEmpty),
      ],
    );

    blocTest<WorklogBloc, WorklogState>(
      'WorkLogEntryAdded mencatat entri lalu memuat ulang buku',
      build: () {
        when(() => sourceRepository.listSources()).thenAnswer((_) async => right([source]));
        when(() => worklogRepository.listBooks('gaji-menul')).thenAnswer((_) async => right(const []));
        when(() => worklogRepository.addEntry(sourceId: any(named: 'sourceId'), entry: any(named: 'entry')))
            .thenAnswer(
          (_) async => right(
            BillingBook(id: 'b1', sourceId: 'gaji-menul', startDate: DateTime(2026, 9), entries: [
              WorkLogEntry(id: 'e1', date: DateTime(2026, 9), hours: 8, startsNewBook: true),
            ]),
          ),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const WorklogOpened());
        await Future<void>.delayed(Duration.zero);
        // Setelah WorklogOpened selesai, buku sumber kembali dimuat ulang
        // (stub di atas tetap mengembalikan buku kosong) sebelum entri baru
        // dicatat — pastikan repository `addEntry` yang dipakai, bukan buku
        // kosong hasil `listBooks`.
        when(() => worklogRepository.listBooks('gaji-menul')).thenAnswer(
          (_) async => right([
            BillingBook(id: 'b1', sourceId: 'gaji-menul', startDate: DateTime(2026, 9), entries: [
              WorkLogEntry(id: 'e1', date: DateTime(2026, 9), hours: 8, startsNewBook: true),
            ]),
          ]),
        );
        bloc.add(WorkLogEntryAdded(date: DateTime(2026, 9), hours: 8, startsNewBook: true));
      },
      skip: 4,
      expect: () => [
        isA<WorklogState>().having((s) => s.isLoading, 'isLoading', true),
        isA<WorklogState>().having((s) => s.openBook?.totalHours, 'openBook.totalHours', 8),
      ],
    );

    blocTest<WorklogBloc, WorklogState>(
      'BillingBookClosed menghitung gaji bersih dan menampilkan efek',
      build: () {
        when(() => sourceRepository.listSources()).thenAnswer((_) async => right([source]));
        final openBook = BillingBook(
          id: 'b1',
          sourceId: 'gaji-menul',
          startDate: DateTime(2026, 8, 29),
          entries: [WorkLogEntry(id: 'e1', date: DateTime(2026, 8, 29), hours: 15, startsNewBook: true)],
        );
        when(() => worklogRepository.listBooks('gaji-menul')).thenAnswer((_) async => right([openBook]));
        when(() => worklogRepository.saveBook(any())).thenAnswer((_) async => right(unit));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const WorklogOpened());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BillingBookClosed('b1'));
      },
      skip: 4,
      expect: () => [
        isA<WorklogState>().having((s) => s.effect, 'effect', isNotNull),
      ],
      verify: (_) => verify(() => worklogRepository.saveBook(any())).called(1),
    );
  });
}
