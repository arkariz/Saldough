import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late WalletRepositoryImpl walletRepository;
  late TransactionRepositoryImpl transactionRepository;

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    walletRepository = WalletRepositoryImpl(storage: storage);
    transactionRepository = TransactionRepositoryImpl(storage: storage);
    await walletRepository.saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 500000000, currentBalance: 500000000),
    );
    await walletRepository.saveWallet(
      const Wallet(id: 'gopay', name: 'GoPay', iconKey: 'walletEwallet', initialBalance: 0, currentBalance: 0),
    );
    await walletRepository.saveWallet(
      const Wallet(
        id: 'lama',
        name: 'Dompet Lama',
        iconKey: 'walletCash',
        initialBalance: 0,
        currentBalance: 0,
        isActive: false,
      ),
    );
  });

  RecordBloc buildBloc() {
    return RecordBloc(
      walletRepository: walletRepository,
      recordTransaction: RecordTransaction(
        transactionRepository: transactionRepository,
        recomputeWalletBalances: RecomputeWalletBalances(
          walletRepository: walletRepository,
          transactionRepository: transactionRepository,
        ),
      ),
    );
  }

  Future<int> balanceOf(String walletId) async {
    final wallets = (await walletRepository.listWallets()).getOrElse((_) => throw StateError('expected Right'));
    return wallets.firstWhere((w) => w.id == walletId).currentBalance;
  }

  group('RecordBloc', () {
    test('RecordWalletsLoaded memuat dompet AKTIF saja', () async {
      final bloc = buildBloc()..add(const RecordWalletsLoaded());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      expect(bloc.state.wallets.map((w) => w.id), containsAll(['bca', 'gopay']));
      expect(bloc.state.wallets.map((w) => w.id), isNot(contains('lama')));
    });

    test('IncomeRecorded mencatat transaksi dan menambah saldo dompet tujuan', () async {
      final bloc = buildBloc()
        ..add(IncomeRecorded(walletId: 'bca', amount: 261543800, date: DateTime(2026, 9), note: 'gaji'));
      await bloc.stream.firstWhere((s) => !s.isSaving);

      expect(await balanceOf('bca'), 761543800);
      expect(bloc.state.effect, isA<ShowSnackBarEffect>());
    });

    test('ExpenseRecorded mencatat transaksi dan mengurangi saldo dompet asal', () async {
      final bloc = buildBloc()
        ..add(ExpenseRecorded(walletId: 'bca', amount: 75000, date: DateTime(2026, 9), note: 'kopi', categoryKey: 'makan'));
      await bloc.stream.firstWhere((s) => !s.isSaving);

      expect(await balanceOf('bca'), 499925000);
    });

    test('TransferRecorded mengurangi dompet asal dan menambah dompet tujuan sekaligus', () async {
      final bloc = buildBloc()
        ..add(
          TransferRecorded(fromWalletId: 'bca', toWalletId: 'gopay', amount: 100000000, date: DateTime(2026, 9), note: ''),
        );
      await bloc.stream.firstWhere((s) => !s.isSaving);

      expect(await balanceOf('bca'), 400000000);
      expect(await balanceOf('gopay'), 100000000);
    });

    test('efek berhasil berbeda kalimatnya per jenis transaksi', () async {
      final incomeBloc = buildBloc()
        ..add(IncomeRecorded(walletId: 'bca', amount: 1000, date: DateTime(2026, 9), note: ''));
      await incomeBloc.stream.firstWhere((s) => !s.isSaving);
      final incomeEffect = incomeBloc.state.effect;
      expect(incomeEffect, isA<ShowSnackBarEffect>());

      final transferBloc = buildBloc()
        ..add(
          TransferRecorded(fromWalletId: 'bca', toWalletId: 'gopay', amount: 1000, date: DateTime(2026, 9), note: ''),
        );
      await transferBloc.stream.firstWhere((s) => !s.isSaving);
      final transferEffect = transferBloc.state.effect;
      expect(transferEffect, isA<ShowSnackBarEffect>());

      expect((incomeEffect! as ShowSnackBarEffect).message, isNot((transferEffect! as ShowSnackBarEffect).message));
    });
  });
}
