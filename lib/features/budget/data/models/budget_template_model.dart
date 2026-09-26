import 'package:saldough/features/budget/data/models/budget_model.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';

/// Model serialisasi [BudgetTemplate]. Posnya memakai [BudgetItemModel] yang
/// sama dengan anggaran, supaya bentuk pos di kedua dokumen tidak pernah
/// menyimpang. `plannedAmount` turunan, tidak ditulis.
final class BudgetTemplateModel {
  /// Membuat [BudgetTemplateModel].
  const BudgetTemplateModel({
    required this.id,
    required this.name,
    required this.items,
    required this.isEnabled,
  });

  /// Membaca [BudgetTemplateModel] dari JSON.
  factory BudgetTemplateModel.fromJson(Map<String, dynamic> json) => BudgetTemplateModel(
    id: json['id'] as String,
    name: json['name'] as String,
    items: (json['items'] as List<dynamic>).map((e) => BudgetItemModel.fromJson(e as Map<String, dynamic>)).toList(),
    isEnabled: json['isEnabled'] as bool,
  );

  /// Membuat [BudgetTemplateModel] dari entitas domain [BudgetTemplate].
  factory BudgetTemplateModel.fromEntity(BudgetTemplate template) => BudgetTemplateModel(
    id: template.id,
    name: template.name,
    items: template.items.map(BudgetItemModel.fromEntity).toList(),
    isEnabled: template.isEnabled,
  );

  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  static const schemaVersion = 1;

  /// Identitas template.
  final String id;

  /// Nama template.
  final String name;

  /// Pos bawaan.
  final List<BudgetItemModel> items;

  /// Aktif atau tidak.
  final bool isEnabled;

  /// Menulis [BudgetTemplateModel] ke JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'items': items.map((i) => i.toJson()).toList(),
    'isEnabled': isEnabled,
  };

  /// Mengubah model ini jadi entitas domain [BudgetTemplate].
  BudgetTemplate toEntity() => BudgetTemplate(
    id: id,
    name: name,
    items: items.map((i) => i.toEntity()).toList(),
    isEnabled: isEnabled,
  );
}
