import 'package:saldough/features/grocery/data/models/grocery_item_model.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';

/// Model serialisasi [GroceryPlan].
final class GroceryPlanModel {
  /// Membuat [GroceryPlanModel].
  const GroceryPlanModel({
    required this.id,
    required this.weeklyItems,
    required this.monthlyItems,
    required this.weeksPerMonth,
  });

  /// Membaca [GroceryPlanModel] dari JSON.
  factory GroceryPlanModel.fromJson(Map<String, dynamic> json) => GroceryPlanModel(
        id: json['id'] as String,
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
        id: plan.id,
        weeklyItems: plan.weeklyItems.map(GroceryItemModel.fromEntity).toList(),
        monthlyItems: plan.monthlyItems.map(GroceryItemModel.fromEntity).toList(),
        weeksPerMonth: plan.weeksPerMonth,
      );

  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  ///
  /// 2: `id` ditambahkan saat `GroceryPlan` berubah dari dokumen tunggal
  /// jadi satu dokumen per bulan (tautan 1:1 ke `MonthlyCycle`, laporan
  /// pemilik). Tidak ada migrasi otomatis dari skema 1 — aplikasi belum
  /// dirilis ke luar pengembangan (lihat CLAUDE.md bagian "Status").
  static const schemaVersion = 2;

  /// Identitas rencana, format `YYYY-MM`.
  final String id;

  /// Daftar mingguan.
  final List<GroceryItemModel> weeklyItems;

  /// Daftar bulanan.
  final List<GroceryItemModel> monthlyItems;

  /// Pengali daftar mingguan.
  final int weeksPerMonth;

  /// Menulis [GroceryPlanModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'weeklyItems': weeklyItems.map((i) => i.toJson()).toList(),
        'monthlyItems': monthlyItems.map((i) => i.toJson()).toList(),
        'weeksPerMonth': weeksPerMonth,
      };

  /// Mengubah model jadi entitas domain.
  GroceryPlan toEntity() => GroceryPlan(
        id: id,
        weeklyItems: weeklyItems.map((i) => i.toEntity()).toList(),
        monthlyItems: monthlyItems.map((i) => i.toEntity()).toList(),
        weeksPerMonth: weeksPerMonth,
      );
}
