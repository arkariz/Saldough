import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_item.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';
import 'package:saldough/features/grocery/domain/usecases/calculate_grocery_roll_up.dart';

void main() {
  final calculate = CalculateGroceryRollUp();

  group('CalculateGroceryRollUp', () {
    test('576.600 x 4 + 762.100 = 3.068.500 (kasus nyata, sama dengan baris Bulanan)', () {
      const plan = GroceryPlan(
        weeklyItems: [GroceryItem(id: 'w1', name: 'Belanja mingguan', quantity: 1, unitPrice: 57660000)],
        monthlyItems: [GroceryItem(id: 'm1', name: 'Belanja bulanan', quantity: 1, unitPrice: 76210000)],
      );

      expect(calculate(plan), 306850000);
    });

    test('amountOverride mengabaikan quantity x unitPrice', () {
      // Kasus nyata: sampo 1 x Rp41.300 tapi berharga Rp24.000 (FR-GROC-002).
      const plan = GroceryPlan(
        weeklyItems: [
          GroceryItem(id: 'w1', name: 'Sampo', quantity: 1, unitPrice: 4130000, amountOverride: 2400000),
        ],
        monthlyItems: [],
        weeksPerMonth: 1,
      );

      expect(calculate(plan), 2400000);
    });

    test('weeksPerMonth mengalikan hanya subtotal mingguan, bukan bulanan', () {
      const plan = GroceryPlan(
        weeklyItems: [GroceryItem(id: 'w1', name: 'A', quantity: 1, unitPrice: 10000)],
        monthlyItems: [GroceryItem(id: 'm1', name: 'B', quantity: 1, unitPrice: 5000)],
        weeksPerMonth: 3,
      );

      expect(calculate(plan), 10000 * 3 + 5000);
    });

    test('rencana kosong menghasilkan roll-up nol', () {
      expect(calculate(GroceryPlan.empty()), 0);
    });
  });
}
