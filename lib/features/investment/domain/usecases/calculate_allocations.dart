import 'package:saldough/features/investment/domain/entities/allocation_percentage.dart';
import 'package:saldough/features/investment/domain/entities/goal_allocation_amount.dart';

/// Menghitung nominal tiap pos dari budget investasi dan persentasenya
/// (FR-INV-002). Dart murni, tidak menyentuh penyimpanan.
final class CalculateAllocations {
  /// Menghitung nominal tiap [allocations] dari [investmentBudget].
  List<GoalAllocationAmount> call({
    required int investmentBudget,
    required List<AllocationPercentage> allocations,
  }) {
    return [
      for (final allocation in allocations)
        GoalAllocationAmount(
          goalId: allocation.goalId,
          amount: investmentBudget * allocation.percentage ~/ 100,
        ),
    ];
  }
}
