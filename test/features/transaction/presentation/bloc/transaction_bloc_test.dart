import 'package:bloc_test/bloc_test.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

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
  late MockWalletRepository walletRepository;
  late MockTransactionRepository transactionRepository;

  setUpAll(() {
    registerFallbackValue(fallbackWallet);
    registerFallbackValue(fallbackTransaction);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    walletRepository = MockWalletRepository();
    transactionRepository = MockTransactionRepository();
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
    walletRepository: walletRepository,
    transactionRepository: transactionRepository,
    recordTransaction: RecordTransaction(
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
  void stubMonthSequence(List<List<Transaction>> answers) {
    var call = 0;
    when(() => transactionRepository.listTransactionsInMonth(any())).thenAnswer(
      (_) async {
        final result = Right<Failure, List<Transaction>>(
          answers[call < answers.length ? call : answers.length - 1],
        );
        call++;
        return result;
      },
    );
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
              categoryKey: 'makan',
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
              categoryKey: 'Makan Siang',
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
      'TransactionMonthChanged memuat ulang HANYA transaksi, bukan dompet, dan recompute kategori',
      setUp: () {
        final now = DateTime.now();
        final nextMonth = DateTime(now.year, now.month + 1);
        stubMonthSequence([
          [
            ExpenseTransaction(
              id: 'e1',
              date: DateTime(now.year, now.month),
              amount: 30000,
              note: '',
              walletId: 'bca',
              categoryKey: 'makan',
            ),
          ],
          [
            ExpenseTransaction(
              id: 'e2',
              date: nextMonth,
              amount: 20000,
              note: '',
              walletId: 'bca',
              categoryKey: 'tagihan',
            ),
          ],
        ]);
      },
      build: buildBloc,
      act: (bloc) async {
        final now = DateTime.now();
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        bloc.add(TransactionMonthChanged(DateTime(now.year, now.month + 1)));
      },
      skip: 1,
      verify: (bloc) {
        expect(bloc.state.categoryOptions, ['tagihan']);
        expect(bloc.state.groups.expand((g) => g.transactions).single.id, 'e2');
        verify(() => walletRepository.listWallets()).called(1);
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
