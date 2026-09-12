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
    // UX-09: `_onOpened` sekarang juga memuat daftar siklus untuk pemilih
    // siklus tujuan penyuntikan — bawaan kosong, tes yang butuh daftar
    // sungguhan menimpa stub ini sendiri.
    when(() => writer.listCycleIds()).thenAnswer((_) async => right(const []));
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
        cycleIncomeWriter: writer,
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

    // UX-09: dasar pemilih siklus tujuan penyuntikan -- bukan lagi input
    // `YYYY-MM` bebas.
    blocTest<WorklogBloc, WorklogState>(
      'WorklogOpened memuat daftar siklus yang bisa dipilih untuk penyuntikan',
      build: () {
        when(() => sourceRepository.listSources()).thenAnswer((_) async => right([source]));
        when(() => worklogRepository.listBooks('gaji-menul')).thenAnswer((_) async => right(const []));
        when(() => writer.listCycleIds()).thenAnswer((_) async => right(const ['2026-08', '2026-09']));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const WorklogOpened()),
      skip: 3,
      expect: () => [
        isA<WorklogState>().having((s) => s.cycleIds, 'cycleIds', ['2026-08', '2026-09']),
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
        bloc.add(WorkLogEntryAdded(date: DateTime(2026, 9), hours: 8));
      },
      skip: 4,
      expect: () => [
        isA<WorklogState>().having((s) => s.isLoading, 'isLoading', true),
        isA<WorklogState>().having((s) => s.openBook?.totalHours, 'openBook.totalHours', 8),
      ],
    );

    blocTest<WorklogBloc, WorklogState>(
      // Tidak ada lagi efek snackbar di sini (laporan pemilik: buku ditutup
      // lalu suntik ke siklus terasa dua langkah terputus) -- `WorklogPage`
      // mendeteksi transisi openBook jadi null lewat `BlocListener` sendiri
      // dan menampilkan dialog, bukan bloc yang memancarkan efek.
      'BillingBookClosed menghitung gaji bersih, menutup buku, TANPA efek snackbar',
      build: () {
        when(() => sourceRepository.listSources()).thenAnswer((_) async => right([source]));
        var books = [
          BillingBook(
            id: 'b1',
            sourceId: 'gaji-menul',
            startDate: DateTime(2026, 8, 29),
            entries: [WorkLogEntry(id: 'e1', date: DateTime(2026, 8, 29), hours: 15, startsNewBook: true)],
          ),
        ];
        // `listBooks` mencerminkan hasil `saveBook` terakhir -- buku tertutup
        // yang ditulis `CloseBillingBook` harus kelihatan lagi saat dimuat
        // ulang, bukan salinan lama yang masih terbuka.
        when(() => worklogRepository.listBooks('gaji-menul')).thenAnswer((_) async => right(books));
        when(() => worklogRepository.saveBook(any())).thenAnswer((invocation) async {
          final saved = invocation.positionalArguments.single as BillingBook;
          books = [saved];
          return right(unit);
        });
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const WorklogOpened());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BillingBookClosed('b1'));
      },
      skip: 4,
      expect: () => [
        isA<WorklogState>()
            .having((s) => s.effect, 'effect', isNull)
            .having((s) => s.openBook, 'openBook', isNull)
            .having((s) => s.closedBooks, 'closedBooks', hasLength(1)),
      ],
      verify: (_) => verify(() => worklogRepository.saveBook(any())).called(1),
    );

    blocTest<WorklogBloc, WorklogState>(
      'WorkLogEntryUpdated mengubah jam satu entri pada buku terbuka',
      build: () {
        when(() => sourceRepository.listSources()).thenAnswer((_) async => right([source]));
        var books = [
          BillingBook(
            id: 'b1',
            sourceId: 'gaji-menul',
            startDate: DateTime(2026, 9),
            entries: [WorkLogEntry(id: 'e1', date: DateTime(2026, 9), hours: 5)],
          ),
        ];
        // `listBooks` mencerminkan hasil `saveBook` terakhir, sama seperti
        // tes `BillingBookClosed` -- tanpa ini, buku yang dimuat ulang lewat
        // `WorklogSourceSelected` tetap menunjukkan jam yang lama.
        when(() => worklogRepository.listBooks('gaji-menul')).thenAnswer((_) async => right(books));
        when(() => worklogRepository.saveBook(any())).thenAnswer((invocation) async {
          final saved = invocation.positionalArguments.single as BillingBook;
          books = [saved];
          return right(unit);
        });
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const WorklogOpened());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const WorkLogEntryUpdated(bookId: 'b1', entryId: 'e1', hours: 9));
      },
      skip: 4,
      // `_onEntryUpdated` sendiri tidak memancarkan state -- ia menyimpan
      // lalu memicu ulang `WorklogSourceSelected`, yang memancarkan 2 state
      // berurutan (isLoading, lalu buku termuat ulang), sama seperti
      // `WorkLogEntryAdded` di atas.
      expect: () => [
        isA<WorklogState>().having((s) => s.isLoading, 'isLoading', true),
        isA<WorklogState>().having((s) => s.openBook?.totalHours, 'openBook.totalHours', 9),
      ],
      verify: (_) => verify(
        () => worklogRepository.saveBook(
          any(that: isA<BillingBook>().having((b) => b.entries.single.hours, 'entries.single.hours', 9)),
        ),
      ).called(1),
    );

    blocTest<WorklogBloc, WorklogState>(
      'WorkLogEntryRemoved menghapus satu entri dan menyegarkan startDate',
      build: () {
        when(() => sourceRepository.listSources()).thenAnswer((_) async => right([source]));
        var books = [
          BillingBook(
            id: 'b1',
            sourceId: 'gaji-menul',
            startDate: DateTime(2026, 8, 29),
            entries: [
              WorkLogEntry(id: 'e1', date: DateTime(2026, 8, 29), hours: 5),
              WorkLogEntry(id: 'e2', date: DateTime(2026, 9, 2), hours: 3),
            ],
          ),
        ];
        when(() => worklogRepository.listBooks('gaji-menul')).thenAnswer((_) async => right(books));
        when(() => worklogRepository.saveBook(any())).thenAnswer((invocation) async {
          final saved = invocation.positionalArguments.single as BillingBook;
          books = [saved];
          return right(unit);
        });
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const WorklogOpened());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const WorkLogEntryRemoved(bookId: 'b1', entryId: 'e1'));
      },
      skip: 4,
      expect: () => [
        isA<WorklogState>().having((s) => s.isLoading, 'isLoading', true),
        isA<WorklogState>()
            .having((s) => s.openBook?.totalHours, 'openBook.totalHours', 3)
            .having((s) => s.openBook?.startDate, 'openBook.startDate', DateTime(2026, 9, 2)),
      ],
    );
  });
}
