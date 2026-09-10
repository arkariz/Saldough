import 'package:saldough/features/grocery/data/models/grocery_item_model.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';

/// Model serialisasi [GroceryPlan].
final class GroceryPlanModel {
  /// Membuat [GroceryPlanModel].
  const GroceryPlanModel({required this.weeklyItems, required this.monthlyItems, required this.weeksPerMonth});

  /// Membaca [GroceryPlanModel] dari JSON.
  factory GroceryPlanModel.fromJson(Map<String, dynamic> json) => GroceryPlanModel(
        weeklyItems: (json['weeklyItems'] as List<dynamic>)
            .map((e) => GroceryItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        monthlyItems: (json['monthlyItems'] as List<dynamic>)
            .map((e) => GroceryItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        weeksPerMonth: json['weeksPerMonth'] as int,
      );

  /// Membuat model dari entitas domain.
  factory GroceryPlanModel.fromEntity(GroceryPlan plan) => GroceryPlanModel(
        weeklyItems: plan.weeklyItems.map(GroceryItemModel.fromEntity).toList(),
        monthlyItems: plan.monthlyItems.map(GroceryItemModel.fromEntity).toList(),
        weeksPerMonth: plan.weeksPerMonth,
      );

  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  static const schemaVersion = 1;

  /// Daftar mingguan.
  final List<GroceryItemModel> weeklyItems;

  /// Daftar bulanan.
  final List<GroceryItemModel> monthlyItems;

  /// Pengali daftar mingguan.
  final int weeksPerMonth;

  /// Menulis [GroceryPlanModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'weeklyItems': weeklyItems.map((i) => i.toJson()).toList(),
        'monthlyItems': monthlyItems.map((i) => i.toJson()).toList(),
        'weeksPerMonth': weeksPerMonth,
      };

  /// Mengubah model jadi entitas domain.
  GroceryPlan toEntity() => GroceryPlan(
        weeklyItems: weeklyItems.map((i) => i.toEntity()).toList(),
        monthlyItems: monthlyItems.map((i) => i.toEntity()).toList(),
        weeksPerMonth: weeksPerMonth,
      );
}
