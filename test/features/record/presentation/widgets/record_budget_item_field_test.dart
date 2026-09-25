import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/domain/budget_item_catalog.dart';
import 'package:saldough/features/record/presentation/widgets/record_budget_item_field.dart';

void main() {
  const bca = BudgetItemOption(
    budgetId: 'b1',
    budgetName: 'Rumah tangga',
    itemId: 'beras',
    itemName: 'Beras',
    walletId: 'bca',
    isActive: true,
  );
  const gopay = BudgetItemOption(
    budgetId: 'b2',
    budgetName: 'Jajan',
    itemId: 'kopi',
    itemName: 'Kopi',
    walletId: 'gopay',
    isActive: true,
  );
  const finished = BudgetItemOption(
    budgetId: 'b3',
    budgetName: 'Agustus',
    itemId: 'listrik',
    itemName: 'Listrik',
    walletId: 'bca',
    isActive: false,
  );
  const all = [bca, gopay, finished];

  group('budgetItemChoicesFor (T-4.4)', () {
    test('hanya pos anggaran dompet yang diberikan', () {
      expect(budgetItemChoicesFor(all, 'bca', null), [bca]);
      expect(budgetItemChoicesFor(all, 'gopay', null), [gopay]);
    });

    test('tanpa dompet terpilih, tidak ada pilihan', () {
      expect(budgetItemChoicesFor(all, null, null), isEmpty);
    });

    test('pos anggaran yang tidak aktif hanya muncul kalau sedang dipakai transaksi yang disunting', () {
      expect(budgetItemChoicesFor(all, 'bca', 'listrik'), [bca, finished]);
    });

    test('pilihan yang tersimpan tidak ikut kalau dompetnya lain', () {
      // Transfer dari GoPay yang dulu tertaut pos BCA: pos BCA tidak ditawarkan.
      expect(budgetItemChoicesFor(all, 'gopay', 'beras'), [gopay]);
    });
  });
}
