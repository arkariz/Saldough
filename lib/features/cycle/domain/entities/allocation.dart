import 'package:dependencies/dependencies.dart';

/// Satu pembagian dana investasi ke sebuah pos tujuan.
final class Allocation extends Equatable {
  /// Membuat [Allocation].
  const Allocation({required this.goalId, required this.percentage});

  /// Rujukan ke `Goal`.
  final String goalId;

  /// Persentase, bilangan bulat 0 sampai 100.
  final int percentage;

  @override
  List<Object?> get props => [goalId, percentage];
}
