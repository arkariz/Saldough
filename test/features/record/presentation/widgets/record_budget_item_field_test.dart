import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/domain/budget_item_catalog.dart';
import 'package:saldough/features/record/presentation/widgets/record_budget_item_field.dart';

void main() {
  const beras = BudgetItemOption(
    budgetId: 'b1',
    budgetName: 'Rumah tangga',
    itemId: 'beras',
    itemName: 'Beras',
    walletId: 'bca',
    isActive: true,
  );
  const setoran = BudgetItemOption(
    budgetId: 'b1',
    budgetName: 'Rumah tangga',
    itemId: 'setoran',
    itemName: 'Setoran tabungan',
    walletId: 'bca',
    isActive: true,
    transferToWalletId: 'tabungan',
  );
  const kopi = BudgetItemOption(
    budgetId: 'b2',
    budgetName: 'Jajan',
    itemId: 'kopi',
    itemName: 'Kopi',
    walletId: 'gopay',
    isActive: true,
  );
  const listrik = BudgetItemOption(
    budgetId: 'b3',
    budgetName: 'Agustus',
    itemId: 'listrik',
    itemName: 'Listrik',
    walletId: 'bca',
    isActive: false,
  );
  const all = [beras, setoran, kopi, listrik];

  group('expenseBudgetChoicesFor (ADR-018)', () {
    test('hanya pos PENGELUARAN aktif milik dompet asal', () {
      expect(expenseBudgetChoicesFor(all, 'bca', null), [beras]);
      expect(expenseBudgetChoicesFor(all, 'gopay', null), [kopi]);
    });

    test('pos transfer tidak pernah ditawarkan ke pengeluaran', () {
      expect(expenseBudgetChoicesFor(all, 'bca', 'setoran'), [beras]);
    });

    test('tanpa dompet terpilih, tidak ada pilihan', () {
      expect(expenseBudgetChoicesFor(all, null, null), isEmpty);
    });

    test('pos anggaran tidak aktif hanya muncul kalau sedang dipakai transaksi yang disunting', () {
      expect(expenseBudgetChoicesFor(all, 'bca', 'listrik'), [beras, listrik]);
    });
  });

  group('transferBudgetChoicesFor (ADR-018)', () {
    test('hanya pos TRANSFER dengan dompet asal dan tujuan yang cocok', () {
      expect(transferBudgetChoicesFor(all, 'bca', 'tabungan', null), [setoran]);
    });

    test('dompet tujuan lain: pos transfer tidak ditawarkan', () {
      expect(transferBudgetChoicesFor(all, 'bca', 'gopay', null), isEmpty);
    });

    test('dompet tujuan belum dipilih: belum ada pilihan', () {
      expect(transferBudgetChoicesFor(all, 'bca', null, null), isEmpty);
    });

    test('pos pengeluaran tidak pernah ditawarkan ke transfer', () {
      expect(transferBudgetChoicesFor(all, 'bca', 'tabungan', 'beras'), [setoran]);
    });
  });
}
