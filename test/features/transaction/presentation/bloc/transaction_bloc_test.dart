import 'package:bloc_test/bloc_test.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

import '../../../../helpers/categories.dart';
import '../../../../helpers/mocks.dart';

const _forcedFailure = SystemFailure(
  code: FailureCode('TEST_FORCED_FAILURE'),
  message: 'dipaksa gagal untuk uji',
);
const _writeFailure = SystemFailure(
  code: FailureCode('TEST_WRITE_FAILURE'),
  message: 'tulis gagal',
);

void main() {
  setUp(() => useCategories(['makan', 'Makan Siang', 'tagihan']));

  late MockWalletRepository walletRepository;
  late MockTransactionRepository transactionRepository;

  setUpAll(() {
    registerFallbackValue(fallbackWallet);
    registerFallbackValue(fallbackTransaction);
    registerFallbackValue(DateTime(2026));
  });

  tearDown(() {
    HistoryPeriod.reset();
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial;
  });

  setUp(() {
    walletRepository = MockWalletRepository();
    transactionRepository = MockTransactionRepository();
    when(() => transactionRepository.listAvailableMonths()).thenAnswer((_) async => const Right(<DateTime>[]));
    when(() => walletRepository.listWallets()).thenAnswer(
      (_) async => const Right([
        Wallet(
          id: 'bca',
          name: 'BCA',
          iconKey: 'walletBank',
          initialBalance: 0,
          currentBalance: 500000000,
        ),
        Wallet(
          id: 'gopay',
          name: 'GoPay',
          iconKey: 'walletEwallet',
          initialBalance: 0,
          currentBalance: 0,
        ),
      ]),
    );
  });

  TransactionBloc buildBloc() => TransactionBloc(
    ledgerChanges: LedgerChanges(),
    budgetItemCatalog: stubBudgetItemCatalog(),
    walletRepository: walletRepository,
    transactionRepository: transactionRepository,
    recordTransaction: RecordTransaction(
      ledgerChanges: LedgerChanges(),
      transactionRepository: transactionRepository,
      recomputeWalletBalances: RecomputeWalletBalances(
        walletRepository: walletRepository,
        transactionRepository: transactionRepository,
      ),
    ),
  );

  /// Membuat [transactionRepository.listTransactionsInMonth] mengembalikan
  /// [answers] secara berurutan tiap kali dipanggil -- dipakai untuk uji
  /// yang memuat dua kali (mis. refresh setelah transaksi baru).
  ///
  /// Satu pemuatan periode membaca dokumen bulan sekitarnya (T-19.10), jadi
  /// hanya dokumen BULAN INI yang berisi jawaban; bulan lain kosong dan tidak
  /// dihitung sebagai pemanggilan.
  void stubMonthSequence(List<List<Transaction>> answers) {
    var call = 0;
    when(() => transactionRepository.listTransactionsInMonth(any())).thenAnswer(
      (invocation) async {
        final month = invocation.positionalArguments[0] as DateTime;
        final now = DateTime.now();
        if (month.year != now.year || month.month != now.month) {
          return const Right<Failure, List<Transaction>>(<Transaction>[]);
        }
        final result = Right<Failure, List<Transaction>>(
          answers[call < answers.length ? call : answers.length - 1],
        );
        call++;
        return result;
      },
    );
  }

  /// Dokumen bulan [byMonth] (kunci: tanggal 1 bulan itu); bulan lain kosong.
  void stubMonthly(Map<DateTime, List<Transaction>> byMonth) {
    when(() => transactionRepository.listTransactionsInMonth(any())).thenAnswer((invocation) async {
      final month = invocation.positionalArguments[0] as DateTime;
      return Right<Failure, List<Transaction>>(byMonth[DateTime(month.year, month.month)] ?? const []);
    });
  }

  group('TransactionBloc -- memuat', () {
    blocTest<TransactionBloc, TransactionState>(
      'TransactionStarted memuat dompet dan mengelompokkan transaksi bulan berjalan per tanggal',
      setUp: () {
        final now = DateTime.now();
        stubMonthSequence([
          [
            IncomeTransaction(
              id: 'i1',
              date: DateTime(now.year, now.month, 5),
              amount: 100000,
              note: 'gaji',
              walletId: 'bca',
            ),
            ExpenseTransaction(
              id: 'e1',
              date: DateTime(now.year, now.month, 5),
              amount: 30000,
              note: 'kopi',
              walletId: 'bca',
              categoryId: 'makan',
            ),
            TransferTransaction(
              id: 't1',
              date: DateTime(now.year, now.month, 3),
              amount: 50000,
              note: '',
              fromWalletId: 'bca',
              toWalletId: 'gopay',
            ),
          ],
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const TransactionStarted()),
      skip: 1,
      verify: (bloc) {
        expect(
          bloc.state.wallets.map((w) => w.id),
          containsAll(['bca', 'gopay']),
        );
        expect(bloc.state.groups.length, 2);
        expect(bloc.state.groups.first.date.day, 5, reason: 'terbaru dulu');
        expect(
          bloc.state.groups.first.netSen,
          70000,
          reason: '100000 - 30000, transfer tidak dihitung',
        );
        expect(
          bloc.state.groups.last.transactions.single,
          isA<TransferTransaction>(),
        );
        expect(bloc.state.categoryOptions, ['makan']);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'TransactionRefreshed memuat ulang TANPA pernah menyalakan isLoading',
      setUp: () => stubMonthSequence([
        [],
        [
          IncomeTransaction(
            id: 'baru',
            date: DateTime.now(),
            amount: 100000,
            note: 'gaji',
            walletId: 'bca',
          ),
        ],
      ]),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        bloc.add(const TransactionRefreshed());
      },
      // Skip kedua state dari `TransactionStarted` (loading -> kosong),
      // sisakan hanya state dari `TransactionRefreshed` -- baris ini
      // membuktikan `isLoading` TIDAK pernah true lagi sesudahnya.
      skip: 2,
      expect: () => [
        isA<TransactionState>().having((s) => s.isLoading, 'isLoading', false),
      ],
      verify: (bloc) =>
          expect(bloc.state.groups.single.transactions.single.id, 'baru'),
    );

    blocTest<TransactionBloc, TransactionState>(
      'filter jenis mempersempit hasil dan menghitung typeCounts per jenis',
      setUp: () {
        final now = DateTime.now();
        stubMonthSequence([
          [
            IncomeTransaction(
              id: 'i1',
              date: DateTime(now.year, now.month, 5),
              amount: 100000,
              note: '',
              walletId: 'bca',
            ),
            ExpenseTransaction(
              id: 'e1',
              date: DateTime(now.year, now.month, 5),
              amount: 30000,
              note: '',
              walletId: 'bca',
            ),
          ],
        ]);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        bloc.add(
          const TransactionTypeFilterChanged(TransactionTypeFilter.income),
        );
      },
      skip: 1,
      verify: (bloc) {
        expect(bloc.state.typeCounts[TransactionTypeFilter.all], 2);
        expect(bloc.state.typeCounts[TransactionTypeFilter.income], 1);
        expect(
          bloc.state.groups.expand((g) => g.transactions),
          everyElement(isA<IncomeTransaction>()),
        );
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'pencarian mencocokkan kategori, catatan, dan nama dompet tanpa mengubah ringkasan bulan',
      setUp: () {
        final day = DateTime.now();
        stubMonthSequence([
          [
            ExpenseTransaction(
              id: 'e1',
              date: day,
              amount: 30000,
              note: '',
              walletId: 'bca',
              categoryId: 'Makan Siang',
            ),
            ExpenseTransaction(
              id: 'e2',
              date: day,
              amount: 20000,
              note: 'ojek kantor',
              walletId: 'bca',
            ),
            IncomeTransaction(
              id: 'i1',
              date: day,
              amount: 100000,
              note: '',
              walletId: 'gopay',
            ),
          ],
        ]);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        bloc.add(const TransactionSearchChanged('  MAKAN '));
      },
      skip: 1,
      verify: (bloc) {
        List<String> ids() =>
            bloc.state.groups
                .expand((g) => g.transactions)
                .map((t) => t.id)
                .toList()
              ..sort();
        expect(ids(), ['e1']);
        expect(bloc.state.typeCounts[TransactionTypeFilter.all], 1);
        expect(
          bloc.state.rawTransactions,
          hasLength(3),
          reason: 'ringkasan bulan tidak ikut tersaring pencarian',
        );
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'penyaring dompet ikut menampilkan transfer yang menyentuh dompet itu sebagai asal atau tujuan',
      setUp: () {
        final now = DateTime.now();
        stubMonthSequence([
          [
            TransferTransaction(
              id: 't1',
              date: DateTime(now.year, now.month, 5),
              amount: 50000,
              note: '',
              fromWalletId: 'bca',
              toWalletId: 'gopay',
            ),
          ],
        ]);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        bloc.add(const TransactionWalletFilterChanged('gopay'));
      },
      skip: 1,
      verify: (bloc) =>
          expect(bloc.state.groups.expand((g) => g.transactions), hasLength(1)),
    );

    blocTest<TransactionBloc, TransactionState>(
      'TransactionPeriodStepped mundur memuat ulang HANYA transaksi, bukan dompet, recompute kategori, dan dibagikan lewat HistoryPeriod',
      setUp: () {
        final now = DateTime.now();
        final previous = DateTime(now.year, now.month - 1);
        stubMonthly({
          DateTime(now.year, now.month): [
            ExpenseTransaction(
              id: 'e1',
              date: DateTime(now.year, now.month),
              amount: 30000,
              note: '',
              walletId: 'bca',
              categoryId: 'makan',
            ),
          ],
          previous: [
            ExpenseTransaction(
              id: 'e2',
              date: DateTime(previous.year, previous.month, 10),
              amount: 20000,
              note: '',
              walletId: 'bca',
              categoryId: 'tagihan',
            ),
          ],
        });
        when(
          () => transactionRepository.listAvailableMonths(),
        ).thenAnswer((_) async => Right([previous, DateTime(now.year, now.month)]));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        bloc.add(const TransactionPeriodStepped(forward: false));
      },
      skip: 1,
      verify: (bloc) {
        final now = DateTime.now();
        expect(bloc.state.categoryOptions, ['tagihan']);
        expect(bloc.state.groups.expand((g) => g.transactions).single.id, 'e2');
        expect(bloc.state.isCurrent, isFalse);
        expect(bloc.state.canGoBack, isFalse, reason: 'bulan pertama pencatatan');
        expect(HistoryPeriod.anchor, DateTime(now.year, now.month - 1));
        verify(() => walletRepository.listWallets()).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'periode ikut bergeser ketika segmen Analisis mengubah HistoryPeriod, dan kembali ke berjalan saat dikosongkan',
      setUp: () {
        final now = DateTime.now();
        stubMonthly({
          DateTime(now.year, now.month - 1): [
            ExpenseTransaction(
              id: 'lalu',
              date: DateTime(now.year, now.month - 1, 12),
              amount: 1000,
              note: '',
              walletId: 'bca',
            ),
          ],
        });
      },
      build: buildBloc,
      act: (bloc) async {
        final now = DateTime.now();
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        HistoryPeriod.notifier.value = DateTime(now.year, now.month - 1);
        await bloc.stream.firstWhere((s) => !s.isLoading && !s.isCurrent);
        HistoryPeriod.reset();
        await bloc.stream.firstWhere((s) => !s.isLoading && s.isCurrent);
      },
      verify: (bloc) {
        expect(bloc.state.isCurrent, isTrue);
        expect(bloc.state.groups, isEmpty);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'awal bulan 25: hanya anggota periode 25-24 yang dimuat, dari dokumen bulan yang disentuh',
      setUp: () {
        final now = DateTime.now();
        ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.single(const FinancialMonthStart.day(25));
        final period = ActiveFinancialMonth.periodOf(now);
        final inside = period.start.add(const Duration(days: 2));
        stubMonthly({
          for (
            var m = DateTime(period.start.year, period.start.month - 1);
            m.isBefore(period.end);
            m = DateTime(m.year, m.month + 1)
          )
            m: [
              ExpenseTransaction(
                id: 'x${m.month}',
                date: DateTime(m.year, m.month, 10),
                amount: 500,
                note: '',
                walletId: 'bca',
              ),
            ],
          DateTime(inside.year, inside.month): [
            ExpenseTransaction(id: 'in', date: inside, amount: 7000, note: '', walletId: 'bca'),
          ],
        });
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const TransactionStarted()),
      skip: 1,
      verify: (bloc) {
        final ids = bloc.state.rawTransactions.map((t) => t.id).toList();
        expect(ids, contains('in'));
        expect(
          bloc.state.rawTransactions.every((t) => bloc.state.period.contains(t.date)),
          isTrue,
          reason: 'hanya anggota periode 25-24',
        );
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'gaji 23 tertaut kemunculan 25: tampil di periode yang mulai 25, bukan di periode sebelumnya (contoh D)',
      setUp: () {
        ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.single(const FinancialMonthStart.day(25));
        stubMonthly({
          DateTime(2026, 9): [
            IncomeTransaction(
              id: 'gaji',
              date: DateTime(2026, 9, 23, 9),
              amount: 1200000000,
              note: '',
              walletId: 'bca',
            ).withRecurrence(RecurrenceLink(ruleId: 'gaji', occurrenceDate: DateTime(2026, 9, 25))),
          ],
        });
      },
      build: buildBloc,
      act: (bloc) async {
        HistoryPeriod.notifier.value = DateTime(2026, 9, 25);
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading && s.rawTransactions.isNotEmpty);
        HistoryPeriod.notifier.value = DateTime(2026, 8, 25);
        await bloc.stream.firstWhere((s) => !s.isLoading && s.rawTransactions.isEmpty);
      },
      verify: (bloc) {
        expect(bloc.state.period.start, DateTime(2026, 8, 25));
        expect(bloc.state.rawTransactions, isEmpty);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'kegagalan pembacaan dompet menyetel loadFailed true, bukan keadaan kosong',
      setUp: () => when(
        () => walletRepository.listWallets(),
      ).thenAnswer((_) async => const Left(_forcedFailure)),
      build: buildBloc,
      act: (bloc) => bloc.add(const TransactionStarted()),
      skip: 1,
      expect: () => [
        isA<TransactionState>()
            .having((s) => s.loadFailed, 'loadFailed', true)
            .having((s) => s.rawTransactions, 'rawTransactions', isEmpty),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'kegagalan pembacaan transaksi menyetel loadFailed true, pemuatan berhasil berikutnya menyetelnya balik',
      setUp: () {
        var call = 0;
        when(
          () => transactionRepository.listTransactionsInMonth(any()),
        ).thenAnswer((_) async {
          call++;
          return call == 1
              ? const Left(_forcedFailure)
              : const Right(<Transaction>[]);
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        bloc.add(const TransactionStarted());
      },
      // Skip loading+galat dari dispatch PERTAMA dan loading dari dispatch
      // KEDUA, sisakan hanya state akhir yang berhasil.
      skip: 3,
      expect: () => [
        isA<TransactionState>().having(
          (s) => s.loadFailed,
          'loadFailed',
          false,
        ),
      ],
    );
  });

  group('TransactionBloc -- pencarian lintas bulan (T-8.2, UX-6)', () {
    void stubMonthlyTransactions(Map<DateTime, List<Transaction>> byMonth) => stubMonthly(byMonth);

    blocTest<TransactionBloc, TransactionState>(
      'tidak memindai apa pun kalau kata kunci pencarian kosong',
      setUp: () => stubMonthlyTransactions(const {}),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        bloc.add(const TransactionSearchAcrossMonthsRequested());
      },
      skip: 1,
      verify: (bloc) {
        expect(bloc.state.crossMonthScannedMonths, isEmpty);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'memindai bulan sebelumnya dan menemukan transaksi yang cocok, lalu berhenti karena riwayat habis',
      setUp: () {
        stubMonthlyTransactions({
          DateTime(2026, 8): [
            ExpenseTransaction(id: 'agu1', date: DateTime(2026, 8, 15), amount: 40000, note: 'tagihan listrik', walletId: 'bca'),
          ],
          DateTime(2026, 7): [
            ExpenseTransaction(id: 'jul1', date: DateTime(2026, 7, 10), amount: 10000, note: 'lain-lain', walletId: 'bca'),
          ],
        });
        when(() => transactionRepository.listAvailableMonths()).thenAnswer(
          (_) async => Right([DateTime(2026, 7), DateTime(2026, 8), DateTime(2026, 9)]),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        HistoryPeriod.notifier.value = DateTime(2026, 9);
        await bloc.stream.firstWhere((s) => !s.isLoading && s.period.start == DateTime(2026, 9));
        bloc
          ..add(const TransactionSearchChanged('tagihan'))
          ..add(const TransactionSearchAcrossMonthsRequested());
        await bloc.stream.firstWhere((s) => !s.isSearchingCrossMonth && s.crossMonthScannedMonths.isNotEmpty);
      },
      verify: (bloc) {
        expect(bloc.state.crossMonthScannedMonths, containsAll([DateTime(2026, 8), DateTime(2026, 7)]));
        expect(bloc.state.crossMonthGroups.expand((g) => g.transactions).map((t) => t.id), ['agu1']);
        expect(bloc.state.crossMonthExhausted, isTrue);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'mengubah kata kunci pencarian mereset hasil pindai lintas bulan sebelumnya',
      setUp: () {
        stubMonthlyTransactions({
          DateTime(2026, 8): [
            ExpenseTransaction(id: 'agu1', date: DateTime(2026, 8, 15), amount: 40000, note: 'tagihan listrik', walletId: 'bca'),
          ],
        });
        when(() => transactionRepository.listAvailableMonths()).thenAnswer(
          (_) async => Right([DateTime(2026, 8), DateTime(2026, 9)]),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        HistoryPeriod.notifier.value = DateTime(2026, 9);
        await bloc.stream.firstWhere((s) => !s.isLoading && s.period.start == DateTime(2026, 9));
        bloc
          ..add(const TransactionSearchChanged('tagihan'))
          ..add(const TransactionSearchAcrossMonthsRequested());
        await bloc.stream.firstWhere((s) => !s.isSearchingCrossMonth && s.crossMonthScannedMonths.isNotEmpty);
        bloc.add(const TransactionSearchChanged('lain'));
      },
      verify: (bloc) {
        expect(bloc.state.crossMonthScannedMonths, isEmpty);
        expect(bloc.state.crossMonthGroups, isEmpty);
        expect(bloc.state.crossMonthExhausted, isFalse);
      },
    );
  });

  group('TransactionBloc -- sunting dan hapus (T-2.6, FR-TXN-005)', () {
    final day = DateTime.now();

    setUp(() {
      when(
        () => transactionRepository.saveTransaction(
          any(),
          previousDate: any(named: 'previousDate'),
        ),
      ).thenAnswer(
        (_) async => const Right(unit),
      );
      when(
        () => transactionRepository.deleteTransaction(any(), any()),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => walletRepository.saveWallet(any()),
      ).thenAnswer((_) async => const Right(unit));
    });

    blocTest<TransactionBloc, TransactionState>(
      'menyunting nominal menimpa transaksi (bukan menambah), menghitung ulang saldo, dan memuat ulang daftar',
      setUp: () {
        final original = IncomeTransaction(
          id: 'i1',
          date: day,
          amount: 100000,
          note: 'gaji',
          walletId: 'bca',
        );
        stubMonthSequence([
          [original],
          [
            IncomeTransaction(
              id: 'i1',
              date: day,
              amount: 250000,
              note: 'gaji',
              walletId: 'bca',
            ),
          ],
        ]);
        when(() => transactionRepository.listAllTransactions()).thenAnswer(
          (_) async => Right([
            IncomeTransaction(
              id: 'i1',
              date: day,
              amount: 250000,
              note: 'gaji',
              walletId: 'bca',
            ),
          ]),
        );
        // Setelah recompute menulis saldo baru, pemuatan ulang berikutnya
        // (`_afterWrite`) harus melihat dompet yang SUDAH segar -- mock
        // tidak mengingat `saveWallet` sebelumnya, jadi nilai "sesudah
        // ditulis" ini dinyatakan eksplisit di sini.
        when(() => walletRepository.listWallets()).thenAnswer(
          (_) async => const Right([
            Wallet(
              id: 'bca',
              name: 'BCA',
              iconKey: 'walletBank',
              initialBalance: 0,
              currentBalance: 250000,
            ),
            Wallet(
              id: 'gopay',
              name: 'GoPay',
              iconKey: 'walletEwallet',
              initialBalance: 0,
              currentBalance: 0,
            ),
          ]),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        bloc.add(
          TransactionUpdated(
            original: IncomeTransaction(
              id: 'i1',
              date: day,
              amount: 100000,
              note: 'gaji',
              walletId: 'bca',
            ),
            updated: IncomeTransaction(
              id: 'i1',
              date: day,
              amount: 250000,
              note: 'gaji',
              walletId: 'bca',
            ),
          ),
        );
      },
      skip: 1,
      verify: (bloc) {
        final state = bloc.state;
        expect(state.rawTransactions.single.amount, 250000);
        expect(
          state.wallets.firstWhere((w) => w.id == 'bca').currentBalance,
          250000,
          reason: 'dompet di state ikut segar',
        );
        expect(
          state.isLoading,
          isFalse,
          reason: 'daftar tidak boleh berkedip jadi kerangka pemuatan',
        );
        expect(state.effect, isA<ShowSnackBarEffect>());
        final saved =
            verify(
                  () => walletRepository.saveWallet(captureAny()),
                ).captured.single
                as Wallet;
        expect(saved.currentBalance, 250000);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'memindahkan transaksi ke dompet lain menghitung ulang saldo dompet LAMA dan BARU',
      setUp: () {
        stubMonthSequence([
          [
            IncomeTransaction(
              id: 'i1',
              date: day,
              amount: 100000,
              note: 'gaji',
              walletId: 'bca',
            ),
          ],
          [],
        ]);
        when(() => transactionRepository.listAllTransactions()).thenAnswer(
          (_) async => Right([
            IncomeTransaction(
              id: 'i1',
              date: day,
              amount: 100000,
              note: 'gaji',
              walletId: 'gopay',
            ),
          ]),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        bloc.add(
          TransactionUpdated(
            original: IncomeTransaction(
              id: 'i1',
              date: day,
              amount: 100000,
              note: 'gaji',
              walletId: 'bca',
            ),
            updated: IncomeTransaction(
              id: 'i1',
              date: day,
              amount: 100000,
              note: 'gaji',
              walletId: 'gopay',
            ),
          ),
        );
      },
      skip: 1,
      verify: (bloc) {
        final saved = verify(
          () => walletRepository.saveWallet(captureAny()),
        ).captured.cast<Wallet>();
        expect(
          saved.firstWhere((w) => w.id == 'bca').currentBalance,
          0,
          reason: 'dompet lama kehilangan transaksinya',
        );
        expect(
          saved.firstWhere((w) => w.id == 'gopay').currentBalance,
          100000,
          reason: 'dompet baru menerimanya',
        );
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'menghapus mengembalikan saldo dompet ke keadaan sebelum transaksi itu ada',
      setUp: () {
        stubMonthSequence([
          [
            IncomeTransaction(
              id: 'i1',
              date: day,
              amount: 100000,
              note: 'gaji',
              walletId: 'bca',
            ),
          ],
          [],
        ]);
        when(
          () => transactionRepository.listAllTransactions(),
        ).thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        bloc.add(
          TransactionDeleted(
            IncomeTransaction(
              id: 'i1',
              date: day,
              amount: 100000,
              note: 'gaji',
              walletId: 'bca',
            ),
          ),
        );
      },
      skip: 1,
      verify: (bloc) {
        expect(bloc.state.rawTransactions, isEmpty);
        expect(bloc.state.groups, isEmpty);
        final saved =
            verify(
                  () => walletRepository.saveWallet(captureAny()),
                ).captured.single
                as Wallet;
        expect(saved.currentBalance, 0);
        // UX-8: bukan dialog konfirmasi -- efek yang dipancarkan sesudah
        // hapus adalah `CallbackEffect` (menampilkan snackbar "Urungkan"),
        // bukan `ShowSnackBarEffect` polos yang dipakai sunting/urungkan.
        expect(bloc.state.effect, isA<CallbackEffect>());
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'menghapus transfer menghitung ulang KEDUA dompetnya',
      setUp: () {
        final transfer = TransferTransaction(
          id: 't1',
          date: day,
          amount: 50000,
          note: '',
          fromWalletId: 'bca',
          toWalletId: 'gopay',
        );
        stubMonthSequence([
          [transfer],
          [],
        ]);
        when(
          () => transactionRepository.listAllTransactions(),
        ).thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        bloc.add(
          TransactionDeleted(
            TransferTransaction(
              id: 't1',
              date: day,
              amount: 50000,
              note: '',
              fromWalletId: 'bca',
              toWalletId: 'gopay',
            ),
          ),
        );
      },
      skip: 1,
      verify: (bloc) {
        final saved = verify(
          () => walletRepository.saveWallet(captureAny()),
        ).captured.cast<Wallet>();
        expect(saved.firstWhere((w) => w.id == 'bca').currentBalance, 0);
        expect(saved.firstWhere((w) => w.id == 'gopay').currentBalance, 0);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'gagal menulis memancarkan galat dan TIDAK mengubah daftar',
      setUp: () {
        stubMonthSequence([
          [
            IncomeTransaction(
              id: 'i1',
              date: day,
              amount: 100000,
              note: 'gaji',
              walletId: 'bca',
            ),
          ],
        ]);
        when(
          () => transactionRepository.saveTransaction(
            any(),
            previousDate: any(named: 'previousDate'),
          ),
        ).thenAnswer((_) async => const Left(_writeFailure));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        bloc.add(
          TransactionUpdated(
            original: IncomeTransaction(
              id: 'i1',
              date: day,
              amount: 100000,
              note: 'gaji',
              walletId: 'bca',
            ),
            updated: IncomeTransaction(
              id: 'i1',
              date: day,
              amount: 999,
              note: 'x',
              walletId: 'bca',
            ),
          ),
        );
      },
      skip: 1,
      verify: (bloc) {
        expect(
          (bloc.state.effect! as ShowSnackBarEffect).severity,
          FeedbackSeverity.error,
        );
        expect(
          bloc.state.rawTransactions.single.amount,
          100000,
          reason: 'daftar tidak berubah kalau tulis gagal',
        );
        verifyNever(() => walletRepository.saveWallet(any()));
      },
    );
  });
}
