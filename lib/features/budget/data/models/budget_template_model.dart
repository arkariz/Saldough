import 'package:saldough/features/budget/data/models/budget_model.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_schedule.dart';
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
    this.schedule,
  });

  /// Membaca [BudgetTemplateModel] dari JSON.
  factory BudgetTemplateModel.fromJson(Map<String, dynamic> json) => BudgetTemplateModel(
    id: json['id'] as String,
    name: json['name'] as String,
    items: (json['items'] as List<dynamic>).map((e) => BudgetItemModel.fromJson(e as Map<String, dynamic>)).toList(),
    isEnabled: json['isEnabled'] as bool,
    schedule: switch (json['schedule']) {
      final Map<String, dynamic> s => BudgetSchedule(
        walletId: s['walletId'] as String,
        period: BudgetPeriod.values.byName(s['period'] as String),
        anchorDate: DateTime.parse(s['anchorDate'] as String),
        isActive: s['isActive'] as bool,
      ),
      _ => null,
    },
  );

  /// Membuat [BudgetTemplateModel] dari entitas domain [BudgetTemplate].
  factory BudgetTemplateModel.fromEntity(BudgetTemplate template) => BudgetTemplateModel(
    id: template.id,
    name: template.name,
    items: template.items.map(BudgetItemModel.fromEntity).toList(),
    isEnabled: template.isEnabled,
    schedule: template.schedule,
  );

  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  static const schemaVersion = 2;

  /// Identitas template.
  final String id;

  /// Nama template.
  final String name;

  /// Pos bawaan.
  final List<BudgetItemModel> items;

  /// Aktif atau tidak.
  final bool isEnabled;

  /// Jadwal anggaran rutin (skema 2, ADR-036); `null` untuk template biasa.
  final BudgetSchedule? schedule;

  /// Menulis [BudgetTemplateModel] ke JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'items': items.map((i) => i.toJson()).toList(),
    'isEnabled': isEnabled,
    if (schedule case final s?)
      'schedule': {
        'walletId': s.walletId,
        'period': s.period.name,
        'anchorDate': s.anchorDate.toIso8601String(),
        'isActive': s.isActive,
      },
  };

  /// Mengubah model ini jadi entitas domain [BudgetTemplate].
  BudgetTemplate toEntity() => BudgetTemplate(
    id: id,
    name: name,
    items: items.map((i) => i.toEntity()).toList(),
    isEnabled: isEnabled,
    schedule: schedule,
  );
}
