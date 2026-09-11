import 'package:saldough/features/cycle/data/models/allocation_model.dart';
import 'package:saldough/features/cycle/domain/entities/investment_plan.dart';

/// Model serialisasi [InvestmentPlan].
final class InvestmentPlanModel {
  /// Membuat [InvestmentPlanModel].
  const InvestmentPlanModel({
    required this.returnDeposit,
    required this.allocations,
  });

  /// Membaca [InvestmentPlanModel] dari JSON.
  factory InvestmentPlanModel.fromJson(Map<String, dynamic> json) =>
      InvestmentPlanModel(
        returnDeposit: json['returnDeposit'] as int,
        allocations: (json['allocations'] as List<dynamic>)
            .map((e) => AllocationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Membuat model dari entitas domain.
  factory InvestmentPlanModel.fromEntity(InvestmentPlan plan) =>
      InvestmentPlanModel(
        returnDeposit: plan.returnDeposit,
        allocations: plan.allocations.map(AllocationModel.fromEntity).toList(),
      );

  /// Tambahan dana dalam sen.
  final int returnDeposit;

  /// Pembagian per pos.
  final List<AllocationModel> allocations;

  /// Menulis [InvestmentPlanModel] ke JSON.
  Map<String, dynamic> toJson() => {
    'returnDeposit': returnDeposit,
    'allocations': allocations.map((a) => a.toJson()).toList(),
  };

  /// Mengubah model jadi entitas domain.
  InvestmentPlan toEntity() => InvestmentPlan(
    returnDeposit: returnDeposit,
    allocations: allocations.map((a) => a.toEntity()).toList(),
  );
}
