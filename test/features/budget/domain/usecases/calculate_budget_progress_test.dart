import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_status.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

void main() {
  const calculate = CalculateBudgetProgress();
  final now = DateTime(2026, 9, 15);

  // Anggaran bulanan nyata pemilik: subtotal mingguan Rp576.600 × 4 +
  // subtotal bulanan Rp762.100 = Rp3.068.500 (DOMAIN_MODEL.md).
  final budget = Budget(
    id: 'b1',
    name: 'Rumah tangga',
    walletId: 'bca',
    period: BudgetPeriod.monthly,
    startDate: DateTime(2026, 9),
    plannedAmount: 306850000,
    items: const [
      BudgetItem(id: 'mingguan', name: 'Belanja mingguan', quantity: 4, unitPrice: 57660000),
      BudgetItem(id: 'bulanan', name: 'Belanja bulanan', enteredAmount: 76210000),
      BudgetItem(id: 'tabungan', name: 'Setoran tabungan', enteredAmount: 50000000),
    ],
  );

  ExpenseTransaction expense(String id, int amount, {String walletId = 'bca', String? item}) =>
      ExpenseTransaction(id: id, date: DateTime(2026, 9, 5), amount: amount, note: '', walletId: walletId, budgetItemId: item);

  TransferTransaction transfer(String id, int amount, {String from = 'bca', String to = 'tabungan', String? item}) =>
      TransferTransaction(id: id, date: DateTime(2026, 9, 6), amount: amount, note: '', fromWalletId: from, toWalletId: to, budgetItemId: item);

  group('CalculateBudgetProgress', () {
    test('pos yang dirinci: 4 × Rp576.600 = Rp2.306.400, dan jumlah seluruh pos = rencana Rp3.068.500', () {
      expect(budget.items[0].plannedAmount, 230640000);
      final itemsTotal = budget.items.take(2).fold(0, (sum, i) => sum + i.plannedAmount);
      expect(itemsTotal, 306850000);
    });

    test('tanpa transaksi: spent 0, sisa = rencana, seluruh pos belum terpakai', () {
      final result = calculate(budget, const [], now: now);
      expect(result.spent, 0);
      expect(result.remaining, 306850000);
      expect(result.progress, 0);
      expect(result.items.map((i) => i.status), everyElement(BudgetItemStatus.planned));
    });

    test('pengeluaran tertaut dari dompet anggaran menambah spent pos itu', () {
      final result = calculate(budget, [expense('e1', 57660000, item: 'mingguan')], now: now);
      expect(result.items[0].spent, 57660000);
      expect(result.items[0].remaining, 172980000);
      expect(result.items[0].progress, 0.25);
      expect(result.spent, 57660000);
      expect(result.remaining, 249190000);
    });

    test('pengeluaran dari dompet lain TIDAK menambah spent walau budgetItemId cocok', () {
      final result = calculate(budget, [expense('e1', 57660000, walletId: 'gopay', item: 'mingguan')], now: now);
      expect(result.items[0].spent, 0);
      expect(result.spent, 0);
    });

    test('pengeluaran tanpa tautan pos tidak terhitung', () {
      final result = calculate(budget, [expense('e1', 57660000)], now: now);
      expect(result.spent, 0);
    });

    test('transfer yang tertaut pos dan keluar dari dompet anggaran menambah spent pos itu', () {
      final result = calculate(budget, [transfer('t1', 50000000, item: 'tabungan')], now: now);
      expect(result.items[2].spent, 50000000);
      expect(result.items[2].status, BudgetItemStatus.completed);
    });

    test('transfer yang fromWalletId-nya bukan dompet anggaran TIDAK menambah spent', () {
      // Masuk KE dompet anggaran, bukan keluar darinya.
      final result = calculate(budget, [transfer('t1', 50000000, from: 'gopay', to: 'bca', item: 'tabungan')], now: now);
      expect(result.items[2].spent, 0);
    });

    test('pemasukan tidak pernah terhitung', () {
      final result = calculate(
        budget,
        [IncomeTransaction(id: 'i1', date: DateTime(2026, 9, 2), amount: 261543800, note: '', walletId: 'bca')],
        now: now,
      );
      expect(result.spent, 0);
    });

    test('tautan ke pos anggaran lain diabaikan', () {
      final result = calculate(budget, [expense('e1', 1000000, item: 'pos-anggaran-lain')], now: now);
      expect(result.spent, 0);
    });

    test('status pos benar di keempat kondisinya', () {
      final result = calculate(
        budget,
        [
          // mingguan: 1 dari 4 minggu → terpakai sebagian
          expense('e1', 57660000, item: 'mingguan'),
          // bulanan: pas rencana → selesai
          expense('e2', 76210000, item: 'bulanan'),
          // tabungan: melebihi rencana → lewat anggaran
          transfer('t1', 60000000, item: 'tabungan'),
        ],
        now: now,
      );
      expect(result.items[0].status, BudgetItemStatus.partiallySpent);
      expect(result.items[1].status, BudgetItemStatus.completed);
      expect(result.items[2].status, BudgetItemStatus.overspent);
      expect(result.items[2].remaining, -10000000);
      expect(result.items[2].progress, 1.2);

      final untouched = calculate(budget, const [], now: now);
      expect(untouched.items[0].status, BudgetItemStatus.planned);
    });

    test('spent anggaran = Σ spent pos, dan sisa boleh negatif', () {
      final small = budget.copyWith(plannedAmount: 50000000);
      final result = calculate(small, [expense('e1', 76210000, item: 'bulanan')], now: now);
      expect(result.spent, 76210000);
      expect(result.remaining, -26210000);
      expect(result.spendingStatus, BudgetItemStatus.overspent);
    });

    test('anggaran tanpa pos: spent selalu 0', () {
      final empty = budget.copyWith(items: const []);
      final result = calculate(empty, [expense('e1', 1000000, item: 'mingguan')], now: now);
      expect(result.spent, 0);
      expect(result.items, isEmpty);
    });

    test('status anggaran: aktif dalam periode, selesai tepat di endDate, nonaktif kalau diarsipkan', () {
      expect(calculate(budget, const [], now: now).status, BudgetStatus.active);
      expect(calculate(budget, const [], now: DateTime(2026, 10)).status, BudgetStatus.finished);
      expect(calculate(budget.copyWith(isArchived: true), const [], now: now).status, BudgetStatus.archived);
    });

    test('transfer yang tertaut anggaran tetap tidak mengubah total saldo seluruh dompet', () {
      const bca = Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 500000000, currentBalance: 0);
      const tabungan = Wallet(id: 'tabungan', name: 'Tabungan', iconKey: 'walletBank', initialBalance: 100000000, currentBalance: 0);
      const balance = CalculateWalletBalance();
      final transactions = [transfer('t1', 50000000, item: 'tabungan')];

      final total = balance(bca, transactions) + balance(tabungan, transactions);

      expect(total, 600000000);
      expect(calculate(budget, transactions, now: now).items[2].spent, 50000000);
    });
  });

  group('progressRatio', () {
    test('rencana nol: 0 kalau belum terpakai, 1 kalau sudah', () {
      expect(progressRatio(spent: 0, plannedAmount: 0), 0);
      expect(progressRatio(spent: 100, plannedAmount: 0), 1);
    });
  });
}
