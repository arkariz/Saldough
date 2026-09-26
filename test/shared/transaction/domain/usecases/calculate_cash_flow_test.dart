import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/transaction/transaction.dart';

void main() {
  const calculate = CalculateCashFlow();
  final september = DateTime(2026, 9, 26);

  test('menjumlahkan pemasukan dan pengeluaran bulan berjalan', () {
    final flow = calculate([
      IncomeTransaction(id: 'gaji', date: DateTime(2026, 9, 25), amount: 1250000000, note: '', walletId: 'bca'),
      IncomeTransaction(
        id: 'freelance',
        date: DateTime(2026, 9, 26, 23, 59),
        amount: 261543800,
        note: '',
        walletId: 'bca',
      ),
      ExpenseTransaction(id: 'belanja', date: DateTime(2026, 9), amount: 57660000, note: '', walletId: 'bca'),
      ExpenseTransaction(id: 'listrik', date: DateTime(2026, 9, 10), amount: 45000000, note: '', walletId: 'gopay'),
    ], month: september);

    expect(flow.income, 1511543800);
    expect(flow.expense, 102660000);
    expect(flow.net, 1408883800);
  });

  test('transfer tidak dihitung sebagai pemasukan maupun pengeluaran', () {
    final flow = calculate([
      TransferTransaction(
        id: 'pindah',
        date: DateTime(2026, 9, 5),
        amount: 100000000,
        note: '',
        fromWalletId: 'bca',
        toWalletId: 'jago',
      ),
    ], month: september);

    expect(flow, const CashFlow(income: 0, expense: 0));
  });

  test('transaksi di luar bulan itu diabaikan, termasuk tahun lain dengan bulan sama', () {
    final flow = calculate([
      IncomeTransaction(id: 'agustus', date: DateTime(2026, 8, 31, 23, 59), amount: 100, note: '', walletId: 'bca'),
      ExpenseTransaction(id: 'oktober', date: DateTime(2026, 10), amount: 200, note: '', walletId: 'bca'),
      ExpenseTransaction(id: 'tahun-lalu', date: DateTime(2025, 9, 15), amount: 300, note: '', walletId: 'bca'),
    ], month: september);

    expect(flow, const CashFlow(income: 0, expense: 0));
  });
}
