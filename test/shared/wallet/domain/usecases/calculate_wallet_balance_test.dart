import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';
import 'package:saldough/shared/wallet/domain/usecases/calculate_wallet_balance.dart';
import 'package:saldough/shared/wallet/domain/wallet.dart';

void main() {
  const calculate = CalculateWalletBalance();

  const wallet = Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 500000000, currentBalance: 0);

  group('CalculateWalletBalance', () {
    test('tanpa transaksi, saldo sama dengan initialBalance', () {
      expect(calculate(wallet, const []), 500000000);
    });

    test(
      'saldo awal 5.000.000, masuk 2.615.438, keluar 3.068.500, transfer keluar 1.000.000 menghasilkan 3.546.938',
      () {
        final transactions = [
          IncomeTransaction(id: 't1', date: DateTime(2026, 9), amount: 261543800, note: 'gaji', walletId: 'bca'),
          ExpenseTransaction(id: 't2', date: DateTime(2026, 9, 5), amount: 306850000, note: 'belanja', walletId: 'bca'),
          TransferTransaction(
            id: 't3',
            date: DateTime(2026, 9, 10),
            amount: 100000000,
            note: 'setoran tabungan',
            fromWalletId: 'bca',
            toWalletId: 'tabungan',
          ),
        ];

        expect(calculate(wallet, transactions), 354693800);
      },
    );

    test('transfer masuk menambah saldo dompet tujuan', () {
      const tabungan = Wallet(
        id: 'tabungan',
        name: 'Tabungan',
        iconKey: 'walletSavings',
        initialBalance: 0,
        currentBalance: 0,
      );
      final transfer = TransferTransaction(
        id: 't1',
        date: DateTime(2026, 9, 10),
        amount: 100000000,
        note: 'setoran tabungan',
        fromWalletId: 'bca',
        toWalletId: 'tabungan',
      );

      expect(calculate(tabungan, [transfer]), 100000000);
    });

    test('transaksi milik dompet lain diabaikan', () {
      final other = ExpenseTransaction(
        id: 't1',
        date: DateTime(2026, 9),
        amount: 50000,
        note: 'kopi',
        walletId: 'gopay',
      );
      expect(calculate(wallet, [other]), wallet.initialBalance);
    });

    test('saldo boleh negatif', () {
      const kosong = Wallet(id: 'w1', name: 'Kartu', iconKey: 'walletCard', initialBalance: 0, currentBalance: 0);
      final expense = ExpenseTransaction(
        id: 't1',
        date: DateTime(2026, 9),
        amount: 150000,
        note: 'tagihan',
        walletId: 'w1',
      );
      expect(calculate(kosong, [expense]), -150000);
    });
  });
}
