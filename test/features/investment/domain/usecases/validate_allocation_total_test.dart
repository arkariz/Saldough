import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/investment/domain/entities/allocation_percentage.dart';
import 'package:saldough/features/investment/domain/usecases/validate_allocation_total.dart';

void main() {
  group('isValidAllocationTotal', () {
    test('total 0 sah — artinya belum dialokasikan', () {
      expect(isValidAllocationTotal(const [AllocationPercentage(goalId: 'a', percentage: 0)]), isTrue);
    });

    test('total 100 sah', () {
      expect(
        isValidAllocationTotal(const [
          AllocationPercentage(goalId: 'a', percentage: 40),
          AllocationPercentage(goalId: 'b', percentage: 60),
        ]),
        isTrue,
      );
    });

    test('daftar kosong (total 0) sah', () {
      expect(isValidAllocationTotal(const []), isTrue);
    });

    test('total selain 0 dan 100 ditolak', () {
      expect(
        isValidAllocationTotal(const [
          AllocationPercentage(goalId: 'a', percentage: 40),
          AllocationPercentage(goalId: 'b', percentage: 30),
        ]),
        isFalse,
      );
    });

    test('total lebih dari 100 ditolak', () {
      expect(
        isValidAllocationTotal(const [
          AllocationPercentage(goalId: 'a', percentage: 70),
          AllocationPercentage(goalId: 'b', percentage: 60),
        ]),
        isFalse,
      );
    });
  });
}
