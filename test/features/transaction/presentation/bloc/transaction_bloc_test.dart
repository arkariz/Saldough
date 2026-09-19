import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Pembungkus [TransactionRepository] yang bisa dipaksa gagal lewat
/// [shouldFail], dipakai untuk menguji `TransactionState.loadFailed` tanpa
/// mocktail (ADR-0010).
final class _FlakyTransactionRepository implements TransactionRepository {
  _FlakyTransactionRepository(this._delegate);

  final TransactionRepository _delegate;

  /// `true` membuat [listTransactionsInMonth] SELALU mengembalikan `Left`.
  bool shouldFail = false;

  @override
  Future<Either<Failure, List<Transaction>>> listTransactionsInMonth(DateTime month) async {
    if (shouldFail) {
      return const Left(SystemFailure(code: FailureCode('TEST_FORCED_FAILURE'), message: 'dipaksa gagal untuk uji'));
    }
    return _delegate.listTransactionsInMonth(month);
  }

  @override
  Future<Either<Failure, List<Transaction>>> listAllTransactions() => _delegate.listAllTransactions();

  @override
  Future<Either<Failure, Unit>> saveTransaction(Transaction transaction, {DateTime? previousDate}) =>
      _delegate.saveTransaction(transaction, previousDate: previousDate);

  @override
  Future<Either<Failure, Unit>> deleteTransaction(String id, DateTime date) => _delegate.deleteTransaction(id, date);
}

void main() {
  late InMemoryKeyValueStorage storage;
  late WalletRepositoryImpl walletRepository;
  late TransactionRepositoryImpl transactionRepository;

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    walletRepository = WalletRepositoryImpl(storage: storage);
    transactionRepository = TransactionRepositoryImpl(storage: storage);
    await walletRepository.saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 500000000),
    );
    await walletRepository.saveWallet(
      const Wallet(id: 'gopay', name: 'GoPay', iconKey: 'walletEwallet', initialBalance: 0, currentBalance: 0),
    );
  });

  TransactionBloc buildBloc({TransactionRepository? repository}) {
    return TransactionBloc(
      walletRepository: walletRepository,
      transactionRepository: repository ?? transactionRepository,
    );
  }

  group('TransactionBloc', () {
    test('TransactionStarted memuat dompet dan mengelompokkan transaksi bulan berjalan per tanggal', () async {
      final now = DateTime.now();
      await transactionRepository.saveTransaction(
        IncomeTransaction(
          id: 'i1',
          date: DateTime(now.year, now.month, 5),
          amount: 100000,
          note: 'gaji',
          walletId: 'bca',
        ),
      );
      await transactionRepository.saveTransaction(
        ExpenseTransaction(
          id: 'e1',
          date: DateTime(now.year, now.month, 5),
          amount: 30000,
          note: 'kopi',
          walletId: 'bca',
          categoryKey: 'makan',
        ),
      );
      await transactionRepository.saveTransaction(
        TransferTransaction(
          id: 't1',
          date: DateTime(now.year, now.month, 3),
          amount: 50000,
          note: '',
          fromWalletId: 'bca',
          toWalletId: 'gopay',
        ),
      );

      final bloc = buildBloc()..add(const TransactionStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      expect(bloc.state.wallets.map((w) => w.id), containsAll(['bca', 'gopay']));
      expect(bloc.state.groups.length, 2);
      // Terbaru dulu -- tanggal 5 sebelum tanggal 3.
      expect(bloc.state.groups.first.date.day, 5);
      expect(bloc.state.groups.first.netSen, 70000); // 100000 - 30000, transfer TIDAK ikut dihitung.
      expect(bloc.state.groups.last.transactions.single, isA<TransferTransaction>());
      expect(bloc.state.categoryOptions, ['makan']);
    });

    test('filter jenis mempersempit hasil dan menghitung typeCounts per jenis', () async {
      final now = DateTime.now();
      await transactionRepository.saveTransaction(
        IncomeTransaction(id: 'i1', date: DateTime(now.year, now.month, 5), amount: 100000, note: '', walletId: 'bca'),
      );
      await transactionRepository.saveTransaction(
        ExpenseTransaction(id: 'e1', date: DateTime(now.year, now.month, 5), amount: 30000, note: '', walletId: 'bca'),
      );

      final bloc = buildBloc()..add(const TransactionStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);
      expect(bloc.state.typeCounts[TransactionTypeFilter.all], 2);
      expect(bloc.state.typeCounts[TransactionTypeFilter.income], 1);

      bloc.add(const TransactionTypeFilterChanged(TransactionTypeFilter.income));
      await bloc.stream.first;

      final allTransactions = bloc.state.groups.expand((g) => g.transactions);
      expect(allTransactions, everyElement(isA<IncomeTransaction>()));
    });

    test('pencarian mencocokkan kategori, catatan, dan nama dompet tanpa mengubah ringkasan bulan', () async {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, 5);
      await transactionRepository.saveTransaction(
        ExpenseTransaction(id: 'e1', date: day, amount: 30000, note: '', walletId: 'bca', categoryKey: 'Makan Siang'),
      );
      await transactionRepository.saveTransaction(
        ExpenseTransaction(id: 'e2', date: day, amount: 20000, note: 'ojek kantor', walletId: 'bca'),
      );
      await transactionRepository.saveTransaction(
        IncomeTransaction(id: 'i1', date: day, amount: 100000, note: '', walletId: 'gopay'),
      );

      final bloc = buildBloc()..add(const TransactionStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      List<String> ids() => bloc.state.groups.expand((g) => g.transactions).map((t) => t.id).toList()..sort();

      bloc.add(const TransactionSearchChanged('  MAKAN '));
      await bloc.stream.first;
      expect(ids(), ['e1']);
      expect(bloc.state.typeCounts[TransactionTypeFilter.all], 1);
      expect(bloc.state.rawTransactions, hasLength(3));

      bloc.add(const TransactionSearchChanged('ojek'));
      await bloc.stream.first;
      expect(ids(), ['e2']);

      bloc.add(const TransactionSearchChanged('gopay'));
      await bloc.stream.first;
      expect(ids(), ['i1']);

      bloc.add(const TransactionSearchChanged(''));
      await bloc.stream.first;
      expect(ids(), ['e1', 'e2', 'i1']);
    });

    test('filter dompet dan kategori mempersempit hasil', () async {
      final now = DateTime.now();
      await transactionRepository.saveTransaction(
        ExpenseTransaction(
          id: 'e1',
          date: DateTime(now.year, now.month, 5),
          amount: 30000,
          note: '',
          walletId: 'bca',
          categoryKey: 'makan',
        ),
      );
      await transactionRepository.saveTransaction(
        ExpenseTransaction(
          id: 'e2',
          date: DateTime(now.year, now.month, 6),
          amount: 40000,
          note: '',
          walletId: 'gopay',
          categoryKey: 'transport',
        ),
      );

      final bloc = buildBloc()..add(const TransactionStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      bloc.add(const TransactionWalletFilterChanged('bca'));
      await bloc.stream.first;
      var transactions = bloc.state.groups.expand((g) => g.transactions).toList();
      expect(transactions.single.id, 'e1');

      bloc.add(const TransactionWalletFilterChanged(null));
      await bloc.stream.first;
      bloc.add(const TransactionCategoryFilterChanged('transport'));
      await bloc.stream.first;
      transactions = bloc.state.groups.expand((g) => g.transactions).toList();
      expect(transactions.single.id, 'e2');
    });

    test('penyaring dompet ikut menampilkan transfer yang menyentuh dompet itu sebagai asal atau tujuan', () async {
      final now = DateTime.now();
      await transactionRepository.saveTransaction(
        TransferTransaction(
          id: 't1',
          date: DateTime(now.year, now.month, 5),
          amount: 50000,
          note: '',
          fromWalletId: 'bca',
          toWalletId: 'gopay',
        ),
      );

      final bloc = buildBloc()..add(const TransactionStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      bloc.add(const TransactionWalletFilterChanged('gopay'));
      await bloc.stream.first;

      expect(bloc.state.groups.expand((g) => g.transactions), hasLength(1));
    });

    test('TransactionMonthChanged memuat ulang HANYA transaksi, bukan dompet, dan recompute kategori', () async {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month);
      final nextMonth = DateTime(now.year, now.month + 1);
      await transactionRepository.saveTransaction(
        ExpenseTransaction(id: 'e1', date: thisMonth, amount: 30000, note: '', walletId: 'bca', categoryKey: 'makan'),
      );
      await transactionRepository.saveTransaction(
        ExpenseTransaction(id: 'e2', date: nextMonth, amount: 20000, note: '', walletId: 'bca', categoryKey: 'tagihan'),
      );

      final bloc = buildBloc()..add(const TransactionStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);
      expect(bloc.state.categoryOptions, ['makan']);

      bloc.add(TransactionMonthChanged(nextMonth));
      await bloc.stream.firstWhere((s) => !s.isLoading);

      expect(bloc.state.month, nextMonth);
      expect(bloc.state.categoryOptions, ['tagihan']);
      expect(bloc.state.groups.expand((g) => g.transactions).single.id, 'e2');
    });

    test('kegagalan pembacaan dompet menyetel loadFailed true, bukan keadaan kosong', () async {
      final failing = _FailingWalletRepository();
      final bloc = TransactionBloc(walletRepository: failing, transactionRepository: transactionRepository)
        ..add(const TransactionStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      expect(bloc.state.loadFailed, isTrue);
      expect(bloc.state.rawTransactions, isEmpty);
    });

    test(
      'kegagalan pembacaan transaksi menyetel loadFailed true, pemuatan berhasil berikutnya menyetelnya balik',
      () async {
        final flaky = _FlakyTransactionRepository(transactionRepository)..shouldFail = true;
        final bloc = TransactionBloc(walletRepository: walletRepository, transactionRepository: flaky)
          ..add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        expect(bloc.state.loadFailed, isTrue);

        flaky.shouldFail = false;
        bloc.add(const TransactionStarted());
        await bloc.stream.firstWhere((s) => !s.isLoading);
        expect(bloc.state.loadFailed, isFalse);
      },
    );
  });
}

/// Dobel gagal untuk [WalletRepository] -- `listWallets()` SELALU
/// mengembalikan `Left`.
final class _FailingWalletRepository implements WalletRepository {
  @override
  Future<Either<Failure, List<Wallet>>> listWallets() async => const Left(
    SystemFailure(code: FailureCode('TEST_FORCED_FAILURE'), message: 'dipaksa gagal untuk uji'),
  );

  @override
  Future<Either<Failure, Unit>> saveWallet(Wallet wallet) => throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> deleteWallet(String id) => throw UnimplementedError();
}
