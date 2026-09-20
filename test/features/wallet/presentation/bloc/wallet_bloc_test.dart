import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Dobel gagal untuk [WalletRepository]: `listWallets()` SELALU `Left`.
final class _FailingWalletRepository implements WalletRepository {
  @override
  Future<Either<Failure, List<Wallet>>> listWallets() async =>
      const Left(SystemFailure(code: FailureCode('TEST_FORCED_FAILURE'), message: 'dipaksa gagal'));

  @override
  Future<Either<Failure, Unit>> saveWallet(Wallet wallet) => throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> deleteWallet(String id) => throw UnimplementedError();
}

void main() {
  late InMemoryKeyValueStorage storage;
  late WalletRepositoryImpl walletRepository;
  late TransactionRepositoryImpl transactionRepository;

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    walletRepository = WalletRepositoryImpl(storage: storage);
    transactionRepository = TransactionRepositoryImpl(storage: storage);
  });

  WalletBloc buildBloc({WalletRepository? wallets}) {
    final repo = wallets ?? walletRepository;
    return WalletBloc(
      walletRepository: repo,
      transactionRepository: transactionRepository,
      recomputeWalletBalances: RecomputeWalletBalances(
        walletRepository: repo,
        transactionRepository: transactionRepository,
      ),
    );
  }

  Future<List<Wallet>> stored() async =>
      (await walletRepository.listWallets()).getOrElse((_) => throw StateError('expected Right'));

  Future<Wallet> storedWallet(String id) async => (await stored()).firstWhere((w) => w.id == id);

  Future<void> seed(Wallet wallet) => walletRepository.saveWallet(wallet);

  Wallet wallet(
    String id, {
    String name = 'BCA',
    int initial = 0,
    int? current,
    bool isActive = true,
    String iconKey = 'walletBank',
  }) => Wallet(
    id: id,
    name: name,
    iconKey: iconKey,
    initialBalance: initial,
    currentBalance: current ?? initial,
    isActive: isActive,
  );

  String? messageOf(WalletState state) => (state.effect as ShowSnackBarEffect?)?.message;

  /// Menunggu state berikutnya yang membawa efek (hasil sebuah penulisan).
  Future<WalletState> nextEffect(WalletBloc bloc) => bloc.stream.firstWhere((s) => s.effect != null);

  group('WalletBloc -- memuat', () {
    test('WalletStarted memuat dompet aktif maupun tidak', () async {
      await seed(wallet('a'));
      await seed(wallet('b', name: 'Lama', isActive: false));

      final bloc = buildBloc()..add(const WalletStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      expect(bloc.state.wallets.map((w) => w.id), ['a', 'b']);
      expect(bloc.state.activeWallets.map((w) => w.id), ['a']);
      expect(bloc.state.inactiveWallets.map((w) => w.id), ['b']);
      expect(bloc.state.loadFailed, isFalse);
    });

    test('kegagalan pembacaan menyalakan loadFailed dan memancarkan galat, bukan daftar kosong', () async {
      final bloc = buildBloc(wallets: _FailingWalletRepository())..add(const WalletStarted());
      final state = await bloc.stream.firstWhere((s) => !s.isLoading);

      expect(state.loadFailed, isTrue);
      expect(state.effect, isA<ShowSnackBarEffect>());
    });

    test('total saldo hanya menjumlahkan dompet AKTIF dan boleh negatif (FR-WAL-003)', () async {
      await seed(wallet('a', current: 100000000));
      await seed(wallet('b', name: 'GoPay', current: -30000000));
      await seed(wallet('c', name: 'Nonaktif', current: 999999999, isActive: false));

      final bloc = buildBloc()..add(const WalletStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      expect(bloc.state.totalBalance, 70000000);
      await seed(wallet('a', current: 10000000));
      await seed(wallet('b', name: 'GoPay', current: -30000000));
      bloc.add(const WalletRefreshed());
      await bloc.stream.firstWhere((s) => s.totalBalance == -20000000);
    });

    test('WalletRefreshed memuat ulang TANPA pernah menyalakan isLoading', () async {
      final bloc = buildBloc()..add(const WalletStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);
      await seed(wallet('baru'));

      final emitted = <WalletState>[];
      final sub = bloc.stream.listen(emitted.add);
      bloc.add(const WalletRefreshed());
      await bloc.stream.firstWhere((s) => s.wallets.isNotEmpty);
      await sub.cancel();

      expect(emitted.any((s) => s.isLoading), isFalse);
    });
  });

  group('WalletBloc -- tambah (FR-WAL-001/002)', () {
    test('menyimpan dompet dengan saldo tercatat = saldo awal dan nama dirapikan', () async {
      final bloc = buildBloc()
        ..add(const WalletAdded(name: '  GoPay  ', iconKey: 'walletEwallet', initialBalance: 25000000));

      final state = await nextEffect(bloc);

      final saved = state.wallets.single;
      expect(saved.name, 'GoPay');
      expect(saved.iconKey, 'walletEwallet');
      expect(saved.initialBalance, 25000000);
      expect(saved.currentBalance, 25000000);
      expect(saved.isActive, isTrue);
      expect(messageOf(state), t.wallet.savedMessage);
    });

    test('saldo awal adalah pernyataan keadaan: TIDAK membuat transaksi apa pun (FR-WAL-002)', () async {
      final bloc = buildBloc()..add(const WalletAdded(name: 'BCA', iconKey: 'walletBank', initialBalance: 500000000));
      await nextEffect(bloc);

      final transactions = (await transactionRepository.listAllTransactions()).getOrElse((_) => throw StateError('x'));
      expect(transactions, isEmpty);
    });

    test('saldo awal nol diterima', () async {
      final bloc = buildBloc()..add(const WalletAdded(name: 'Kosong', iconKey: 'walletCash', initialBalance: 0));
      final state = await nextEffect(bloc);

      expect(state.wallets.single.currentBalance, 0);
    });
  });

  group('WalletBloc -- sunting (FR-WAL-001/002)', () {
    Future<void> seedWithIncome() async {
      // Saldo awal 0, pemasukan 100.000 -> saldo tercatat 100.000.
      await seed(wallet('a'));
      await transactionRepository.saveTransaction(
        IncomeTransaction(id: 'i1', date: DateTime(2026, 9, 5), amount: 10000000, note: '', walletId: 'a'),
      );
      await RecomputeWalletBalances(
        walletRepository: walletRepository,
        transactionRepository: transactionRepository,
      ).forWallets({'a'});
    }

    test('menyunting nama dan ikon TIDAK mengubah saldo tercatat maupun saldo awal', () async {
      await seedWithIncome();
      final bloc = buildBloc()..add(const WalletStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      bloc.add(
        WalletEdited(
          original: bloc.state.wallets.single,
          name: 'BCA Utama',
          iconKey: 'walletSavings',
          isActive: true,
        ),
      );
      final state = await nextEffect(bloc);

      final edited = state.wallets.single;
      expect(edited.name, 'BCA Utama');
      expect(edited.iconKey, 'walletSavings');
      expect(edited.initialBalance, 0);
      expect(edited.currentBalance, 10000000);
      expect(messageOf(state), t.wallet.updatedMessage);
    });

    test('mengganti saldo awal menghitung ulang saldo tercatat dari seluruh transaksi', () async {
      await seedWithIncome();
      final bloc = buildBloc()..add(const WalletStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      bloc.add(
        WalletEdited(
          original: bloc.state.wallets.single,
          name: 'BCA',
          iconKey: 'walletBank',
          isActive: true,
          initialBalance: 50000000,
        ),
      );
      await nextEffect(bloc);

      final edited = await storedWallet('a');
      expect(edited.initialBalance, 50000000);
      expect(edited.currentBalance, 60000000, reason: 'saldo awal baru + pemasukan yang sudah ada');
    });

    test('menonaktifkan dompet mengeluarkannya dari daftar aktif dan total, transaksinya tetap ada', () async {
      await seedWithIncome();
      final bloc = buildBloc()..add(const WalletStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);
      expect(bloc.state.totalBalance, 10000000);

      bloc.add(
        WalletEdited(original: bloc.state.wallets.single, name: 'BCA', iconKey: 'walletBank', isActive: false),
      );
      final state = await nextEffect(bloc);

      expect(state.activeWallets, isEmpty);
      expect(state.inactiveWallets.single.id, 'a');
      expect(state.totalBalance, 0);
      final transactions = (await transactionRepository.listAllTransactions()).getOrElse((_) => throw StateError('x'));
      expect(transactions, hasLength(1));
    });
  });

  group('WalletBloc -- hapus (FR-WAL-001)', () {
    test('dompet tanpa transaksi dihapus', () async {
      await seed(wallet('a'));
      await seed(wallet('b', name: 'GoPay'));
      final bloc = buildBloc()..add(const WalletStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      bloc.add(WalletDeleted(bloc.state.wallets.first));
      final state = await nextEffect(bloc);

      expect(state.wallets.map((w) => w.id), ['b']);
      expect(messageOf(state), t.wallet.deletedMessage);
    });

    test('dompet yang punya transaksi (pemasukan) TIDAK dihapus', () async {
      await seed(wallet('a'));
      await transactionRepository.saveTransaction(
        IncomeTransaction(id: 'i1', date: DateTime(2026, 9, 5), amount: 100, note: '', walletId: 'a'),
      );
      final bloc = buildBloc()..add(const WalletStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      bloc.add(WalletDeleted(bloc.state.wallets.single));
      final state = await nextEffect(bloc);

      expect(messageOf(state), t.wallet.deleteBlockedMessage);
      expect((await stored()).map((w) => w.id), ['a']);
    });

    test('dompet yang hanya muncul sebagai TUJUAN transfer juga tidak boleh dihapus', () async {
      await seed(wallet('a'));
      await seed(wallet('b', name: 'GoPay'));
      await transactionRepository.saveTransaction(
        TransferTransaction(
          id: 't1',
          date: DateTime(2026, 9, 5),
          amount: 100,
          note: '',
          fromWalletId: 'a',
          toWalletId: 'b',
        ),
      );
      final bloc = buildBloc()..add(const WalletStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      bloc.add(WalletDeleted(bloc.state.wallets.last));
      final state = await nextEffect(bloc);

      expect(messageOf(state), t.wallet.deleteBlockedMessage);
      expect((await stored()).map((w) => w.id), ['a', 'b']);
    });
  });
}
