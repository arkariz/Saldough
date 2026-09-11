import 'package:saldough/features/cycle/domain/entities/allocation.dart';

/// Model serialisasi [Allocation].
final class AllocationModel {
  /// Membuat [AllocationModel].
  const AllocationModel({required this.goalId, required this.percentage});

  /// Membaca [AllocationModel] dari JSON.
  factory AllocationModel.fromJson(Map<String, dynamic> json) =>
      AllocationModel(
        goalId: json['goalId'] as String,
        percentage: json['percentage'] as int,
      );

  /// Membuat model dari entitas domain.
  factory AllocationModel.fromEntity(Allocation allocation) => AllocationModel(
    goalId: allocation.goalId,
    percentage: allocation.percentage,
  );

  /// Rujukan ke `Goal`.
  final String goalId;

  /// Persentase, bilangan bulat 0 sampai 100.
  final int percentage;

  /// Menulis [AllocationModel] ke JSON.
  Map<String, dynamic> toJson() => {'goalId': goalId, 'percentage': percentage};

  /// Mengubah model jadi entitas domain.
  Allocation toEntity() => Allocation(goalId: goalId, percentage: percentage);
}
