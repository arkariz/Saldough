import 'package:dependencies/dependencies.dart';

/// Nominal hasil hitung `CalculateAllocations` untuk satu pos pada satu
/// siklus.
final class GoalAllocationAmount extends Equatable {
  /// Membuat [GoalAllocationAmount].
  const GoalAllocationAmount({required this.goalId, required this.amount});

  /// Rujukan ke `Goal`.
  final String goalId;

  /// Nominal dalam sen.
  final int amount;

  @override
  List<Object?> get props => [goalId, amount];
}
