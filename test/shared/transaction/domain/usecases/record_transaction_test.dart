import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/shared/transaction/data/transaction_repository_impl.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';
import 'package:saldough/shared/transaction/domain/usecases/recompute_wallet_balances.dart';
import 'package:saldough/shared/transaction/domain/usecases/record_transaction.dart';
import 'package:saldough/shared/wallet/data/wallet_repository_impl.dart';
import 'package:saldough/shared/wallet/domain/wallet.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late WalletRepositoryImpl walletRepository;
  late TransactionRepositoryImpl transactionRepository;
  late RecordTransaction record;

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    walletRepository = WalletRepositoryImpl(storage: storage);
    transactionRepository = TransactionRepositoryImpl(storage: storage);
    record = RecordTransaction(
      transactionRepository: transactionRepository,
      recomputeWalletBalances: RecomputeWalletBalances(
        walletRepository: walletRepository,
        transactionRepository: transactionRepository,
      ),
    );
    await walletRepository.saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 500000000, currentBalance: 500000000),
    );
    await walletRepository.saveWallet(
      const Wallet(id: 'gopay', name: 'GoPay', iconKey: 'walletEwallet', initialBalance: 0, currentBalance: 0),
    );
  });

  Future<int> balanceOf(String walletId) async {
    final wallets = (await walletRepository.listWallets()).getOrElse((_) => throw StateError('expected Right'));
    return wallets.firstWhere((w) => w.id == walletId).currentBalance;
  }

  group('RecordTransaction', () {
    test('mencatat pemasukan menambah saldo dompet tujuan', () async {
      await record(IncomeTransaction(id: 't1', date: DateTime(2026, 9), amount: 261543800, note: 'gaji', walletId: 'bca'));
      expect(await balanceOf('bca'), 761543800);
    });

    test('mencatat pengeluaran mengurangi saldo dompet asal', () async {
      await record(ExpenseTransaction(id: 't1', date: DateTime(2026, 9), amount: 75000, note: 'kopi', walletId: 'bca'));
      expect(await balanceOf('bca'), 499925000);
    });

    test('mencatat transfer mengurangi dompet asal dan menambah dompet tujuan sekaligus', () async {
      await record(
        TransferTransaction(
          id: 't1',
          date: DateTime(2026, 9),
          amount: 100000000,
          note: 'top up',
          fromWalletId: 'bca',
          toWalletId: 'gopay',
        ),
      );
      expect(await balanceOf('bca'), 400000000);
      expect(await balanceOf('gopay'), 100000000);
    });

    test('menyunting nominal transaksi memperbarui saldo sesuai nilai baru, bukan menambahkannya', () async {
      final expense = ExpenseTransaction(id: 't1', date: DateTime(2026, 9), amount: 75000, note: 'kopi', walletId: 'bca');
      await record(expense);
      expect(await balanceOf('bca'), 499925000);

      final edited = expense.copyWith(amount: 100000);
      await record(edited, previousTransaction: expense);
      expect(await balanceOf('bca'), 499900000);
    });

    test('menyunting transaksi yang memindahkan dompet menghitung ulang KEDUANYA', () async {
      final expense = ExpenseTransaction(id: 't1', date: DateTime(2026, 9), amount: 75000, note: 'kopi', walletId: 'bca');
      await record(expense);
      expect(await balanceOf('bca'), 499925000);
      expect(await balanceOf('gopay'), 0);

      final moved = expense.copyWith(walletId: 'gopay');
      await record(moved, previousTransaction: expense);

      expect(await balanceOf('bca'), 500000000, reason: 'dompet lama kembali ke initialBalance setelah transaksinya pindah');
      expect(await balanceOf('gopay'), -75000);
    });

    test('menghapus transaksi mengembalikan saldo dompet yang terdampak', () async {
      final expense = ExpenseTransaction(id: 't1', date: DateTime(2026, 9), amount: 75000, note: 'kopi', walletId: 'bca');
      await record(expense);
      expect(await balanceOf('bca'), 499925000);

      await record.delete(expense);
      expect(await balanceOf('bca'), 500000000);
    });

    test('menghapus satu kaki transfer mengembalikan saldo KEDUA dompet', () async {
      final transfer = TransferTransaction(
        id: 't1',
        date: DateTime(2026, 9),
        amount: 100000000,
        note: 'top up',
        fromWalletId: 'bca',
        toWalletId: 'gopay',
      );
      await record(transfer);
      expect(await balanceOf('bca'), 400000000);
      expect(await balanceOf('gopay'), 100000000);

      await record.delete(transfer);
      expect(await balanceOf('bca'), 500000000);
      expect(await balanceOf('gopay'), 0);
    });

    test('urutan penulisan: transaksi tetap tersimpan meski penulisan dompet diperiksa sesudahnya', () async {
      await record(IncomeTransaction(id: 't1', date: DateTime(2026, 9), amount: 500000, note: 'gaji', walletId: 'bca'));

      final transactions = (await transactionRepository.listTransactionsInMonth(DateTime(2026, 9)))
          .getOrElse((_) => throw StateError('expected Right'));
      expect(transactions, hasLength(1));
    });
  });
}
