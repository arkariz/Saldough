import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';

void main() {
  group('BudgetPeriod.endFrom (eksklusif)', () {
    test('mingguan: tujuh hari sesudahnya', () {
      expect(BudgetPeriod.weekly.endFrom(DateTime(2026, 9, 28)), DateTime(2026, 10, 5));
    });

    test('bulanan: tanggal yang sama bulan berikutnya', () {
      expect(BudgetPeriod.monthly.endFrom(DateTime(2026, 9)), DateTime(2026, 10));
      expect(BudgetPeriod.monthly.endFrom(DateTime(2026, 12, 25)), DateTime(2027, 1, 25));
    });

    test('bulanan: 31 Januari dijepit ke akhir Februari, tidak meluber ke Maret', () {
      expect(BudgetPeriod.monthly.endFrom(DateTime(2026, 1, 31)), DateTime(2026, 2, 28));
      expect(BudgetPeriod.monthly.endFrom(DateTime(2028, 1, 31)), DateTime(2028, 2, 29));
    });

    test('jam pada startDate diabaikan', () {
      expect(BudgetPeriod.weekly.endFrom(DateTime(2026, 9, 1, 18, 30)), DateTime(2026, 9, 8));
    });
  });

  group('BudgetItem.plannedAmount', () {
    test('diketik langsung', () {
      const item = BudgetItem(id: 'i', name: 'Listrik', enteredAmount: 35000000);
      expect(item.plannedAmount, 35000000);
      expect(item.isItemized, isFalse);
    });

    test('dirinci: jumlah × harga satuan menang atas nominal yang diketik', () {
      const item = BudgetItem(id: 'i', name: 'Ikan kembung', enteredAmount: 1, quantity: 2, unitPrice: 3500000);
      expect(item.plannedAmount, 7000000);
      expect(item.isItemized, isTrue);
    });
  });
}
