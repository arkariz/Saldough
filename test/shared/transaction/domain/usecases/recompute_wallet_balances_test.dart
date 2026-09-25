import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/shared/transaction/data/transaction_repository_impl.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';
import 'package:saldough/shared/transaction/domain/usecases/recompute_wallet_balances.dart';
import 'package:saldough/shared/wallet/data/wallet_repository_impl.dart';
import 'package:saldough/shared/wallet/domain/wallet.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late WalletRepositoryImpl walletRepository;
  late TransactionRepositoryImpl transactionRepository;
  late RecomputeWalletBalances recompute;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    walletRepository = WalletRepositoryImpl(storage: storage);
    transactionRepository = TransactionRepositoryImpl(storage: storage);
    recompute = RecomputeWalletBalances(
      walletRepository: walletRepository,
      transactionRepository: transactionRepository,
    );
  });

  group('RecomputeWalletBalances', () {
    test(
      'saldo tersimpan sama persis dengan saldo turunan — saldo awal 5.000.000, masuk 2.615.438, keluar 3.068.500, '
      'transfer keluar 1.000.000 menghasilkan 3.546.938',
      () async {
        const bca = Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 500000000, currentBalance: 0);
        const tabungan = Wallet(
          id: 'tabungan',
          name: 'Tabungan',
          iconKey: 'walletSavings',
          initialBalance: 0,
          currentBalance: 0,
        );
        await walletRepository.saveWallet(bca);
        await walletRepository.saveWallet(tabungan);

        await transactionRepository.saveTransaction(
          IncomeTransaction(id: 't1', date: DateTime(2026, 9), amount: 261543800, note: 'gaji', walletId: 'bca'),
        );
        await transactionRepository.saveTransaction(
          ExpenseTransaction(id: 't2', date: DateTime(2026, 9, 5), amount: 306850000, note: 'belanja', walletId: 'bca'),
        );
        await transactionRepository.saveTransaction(
          TransferTransaction(
            id: 't3',
            date: DateTime(2026, 9, 10),
            amount: 100000000,
            note: 'setoran tabungan',
            fromWalletId: 'bca',
            toWalletId: 'tabungan',
          ),
        );

        await recompute();

        final wallets = (await walletRepository.listWallets()).getOrElse((_) => throw StateError('expected Right'));
        final savedBca = wallets.firstWhere((w) => w.id == 'bca');
        final savedTabungan = wallets.firstWhere((w) => w.id == 'tabungan');
        expect(savedBca.currentBalance, 354693800);
        expect(savedTabungan.currentBalance, 100000000);
      },
    );

    test('transfer tidak mengubah total saldo seluruh dompet', () async {
      const bca = Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 500000000, currentBalance: 0);
      const gopay = Wallet(
        id: 'gopay',
        name: 'GoPay',
        iconKey: 'walletEwallet',
        initialBalance: 100000000,
        currentBalance: 0,
      );
      await walletRepository.saveWallet(bca);
      await walletRepository.saveWallet(gopay);
      final totalSebelum = bca.initialBalance + gopay.initialBalance;

      await transactionRepository.saveTransaction(
        TransferTransaction(
          id: 't1',
          date: DateTime(2026, 9, 10),
          amount: 100000000,
          note: 'top up GoPay',
          fromWalletId: 'bca',
          toWalletId: 'gopay',
        ),
      );
      await recompute();

      final wallets = (await walletRepository.listWallets()).getOrElse((_) => throw StateError('expected Right'));
      final totalSesudah = wallets.fold<int>(0, (sum, w) => sum + w.currentBalance);
      expect(totalSesudah, totalSebelum);
    });

    test('forWallets hanya menyentuh dompet yang disebutkan', () async {
      const bca = Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 500000000, currentBalance: 999);
      const gopay = Wallet(
        id: 'gopay',
        name: 'GoPay',
        iconKey: 'walletEwallet',
        initialBalance: 100000000,
        currentBalance: 999,
      );
      await walletRepository.saveWallet(bca);
      await walletRepository.saveWallet(gopay);

      await recompute.forWallets({'bca'});

      final wallets = (await walletRepository.listWallets()).getOrElse((_) => throw StateError('expected Right'));
      expect(wallets.firstWhere((w) => w.id == 'bca').currentBalance, 500000000);
      expect(wallets.firstWhere((w) => w.id == 'gopay').currentBalance, 999);
    });

    test('dompet tanpa transaksi apa pun tetap memakai initialBalance', () async {
      const wallet = Wallet(
        id: 'w1',
        name: 'Tunai',
        iconKey: 'walletCash',
        initialBalance: 50000000,
        currentBalance: 0,
      );
      await walletRepository.saveWallet(wallet);

      await recompute();

      final wallets = (await walletRepository.listWallets()).getOrElse((_) => throw StateError('expected Right'));
      expect(wallets.single.currentBalance, 50000000);
    });
  });
}
