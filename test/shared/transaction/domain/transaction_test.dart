import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';

void main() {
  group('Transaction invarian', () {
    test('IncomeTransaction menolak nominal nol', () {
      expect(
        () => IncomeTransaction(id: 't1', date: DateTime(2026, 9), amount: 0, note: '', walletId: 'w1'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('ExpenseTransaction menolak nominal negatif', () {
      expect(
        () => ExpenseTransaction(id: 't1', date: DateTime(2026, 9), amount: -1000, note: '', walletId: 'w1'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('TransferTransaction menolak nominal nol atau negatif', () {
      expect(
        () => TransferTransaction(
          id: 't1',
          date: DateTime(2026, 9),
          amount: 0,
          note: '',
          fromWalletId: 'a',
          toWalletId: 'b',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('TransferTransaction menolak fromWalletId sama dengan toWalletId', () {
      expect(
        () => TransferTransaction(
          id: 't1',
          date: DateTime(2026, 9),
          amount: 100000,
          note: '',
          fromWalletId: 'a',
          toWalletId: 'a',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('nominal positif diterima untuk ketiga jenis', () {
      expect(
        () => IncomeTransaction(id: 't1', date: DateTime(2026, 9), amount: 1, note: '', walletId: 'w1'),
        returnsNormally,
      );
      expect(
        () => ExpenseTransaction(id: 't2', date: DateTime(2026, 9), amount: 1, note: '', walletId: 'w1'),
        returnsNormally,
      );
      expect(
        () => TransferTransaction(
          id: 't3',
          date: DateTime(2026, 9),
          amount: 1,
          note: '',
          fromWalletId: 'a',
          toWalletId: 'b',
        ),
        returnsNormally,
      );
    });

    test('dua transaksi dengan field sama dianggap setara (Equatable)', () {
      final a = ExpenseTransaction(id: 't1', date: DateTime(2026, 9, 5), amount: 50000, note: 'kopi', walletId: 'w1');
      final b = ExpenseTransaction(id: 't1', date: DateTime(2026, 9, 5), amount: 50000, note: 'kopi', walletId: 'w1');
      expect(a, b);
    });

    test('ExpenseTransaction dan TransferTransaction boleh menaut ke pos anggaran', () {
      final expense = ExpenseTransaction(
        id: 't1',
        date: DateTime(2026, 9),
        amount: 100000,
        note: 'belanja',
        walletId: 'w1',
        budgetItemId: 'item1',
      );
      final transfer = TransferTransaction(
        id: 't2',
        date: DateTime(2026, 9),
        amount: 500000,
        note: 'setoran tabungan',
        fromWalletId: 'a',
        toWalletId: 'b',
        budgetItemId: 'item2',
      );
      expect(expense.budgetItemId, 'item1');
      expect(transfer.budgetItemId, 'item2');
    });

    test('copyWith mengganti field yang disebutkan, mempertahankan sisanya', () {
      final income = IncomeTransaction(id: 't1', date: DateTime(2026, 9), amount: 1000, note: 'gaji', walletId: 'w1');
      final updated = income.copyWith(amount: 2000);

      expect(updated.amount, 2000);
      expect(updated.id, 't1');
      expect(updated.walletId, 'w1');
    });
  });
}
