import 'package:dependencies/dependencies.dart';

/// Persentase alokasi satu pos tujuan untuk sebuah siklus (FR-INV-002).
///
/// Bentuknya sengaja terpisah dari `Allocation` milik fitur `cycle` —
/// `investment` tidak mengimpor domain privat fitur lain (ADR-0009).
/// `CycleInvestmentGateway` (diimplementasikan `features/cycle/data/`)
/// menjembatani kedua bentuk ini.
final class AllocationPercentage extends Equatable {
  /// Membuat [AllocationPercentage].
  const AllocationPercentage({required this.goalId, required this.percentage});

  /// Rujukan ke `Goal`.
  final String goalId;

  /// Persentase, bilangan bulat 0 sampai 100.
  final int percentage;

  /// Salinan [AllocationPercentage] dengan [percentage] diganti.
  AllocationPercentage copyWith({int? percentage}) =>
      AllocationPercentage(goalId: goalId, percentage: percentage ?? this.percentage);

  @override
  List<Object?> get props => [goalId, percentage];
}
