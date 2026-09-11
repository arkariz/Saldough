import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/investment/domain/entities/allocation_percentage.dart';
import 'package:saldough/features/investment/domain/usecases/calculate_allocations.dart';

void main() {
  group('CalculateAllocations', () {
    final calculate = CalculateAllocations();

    test('sisa Rp3.086.960: 15% = 463.044 dan 55% = 1.697.828', () {
      final result = calculate(
        investmentBudget: 308696000,
        allocations: const [
          AllocationPercentage(goalId: 'a', percentage: 15),
          AllocationPercentage(goalId: 'b', percentage: 55),
        ],
      );

      expect(result, hasLength(2));
      expect(result[0].goalId, 'a');
      expect(result[0].amount, 46304400);
      expect(result[1].goalId, 'b');
      expect(result[1].amount, 169782800);
    });

    test('sisa Rp5.370.616: 20% = 1.074.123,2 dan 40% = 2.148.246,4 (dibulatkan saat tampil)', () {
      final result = calculate(
        investmentBudget: 537061600,
        allocations: const [
          AllocationPercentage(goalId: 'a', percentage: 20),
          AllocationPercentage(goalId: 'b', percentage: 40),
        ],
      );

      expect(result[0].amount, 107412320);
      expect(result[1].amount, 214824640);
    });

    test('persentase 0 menghasilkan nominal 0', () {
      final result = calculate(
        investmentBudget: 100000000,
        allocations: const [AllocationPercentage(goalId: 'a', percentage: 0)],
      );

      expect(result.single.amount, 0);
    });

    test('daftar alokasi kosong menghasilkan daftar kosong', () {
      final result = calculate(investmentBudget: 100000000, allocations: const []);
      expect(result, isEmpty);
    });
  });
}
