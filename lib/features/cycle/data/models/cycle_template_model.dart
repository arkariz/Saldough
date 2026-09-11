import 'package:saldough/features/cycle/data/models/allocation_model.dart';
import 'package:saldough/features/cycle/data/models/budget_line_model.dart';
import 'package:saldough/features/cycle/data/models/income_line_model.dart';
import 'package:saldough/features/cycle/domain/entities/cycle_template.dart';

/// Model serialisasi [CycleTemplate] — dokumen tunggal, bukan per bulan.
final class CycleTemplateModel {
  /// Membuat [CycleTemplateModel].
  const CycleTemplateModel({
    required this.schemaVersion,
    required this.incomeLines,
    required this.budgetLines,
    required this.defaultAllocations,
  });

  /// Membaca [CycleTemplateModel] dari JSON.
  factory CycleTemplateModel.fromJson(Map<String, dynamic> json) =>
      CycleTemplateModel(
        schemaVersion: json['schemaVersion'] as int,
        incomeLines: (json['incomeLines'] as List<dynamic>)
            .map((e) => IncomeLineModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        budgetLines: (json['budgetLines'] as List<dynamic>)
            .map((e) => BudgetLineModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        defaultAllocations: (json['defaultAllocations'] as List<dynamic>)
            .map((e) => AllocationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Membuat model dari entitas domain, siap disimpan dengan
  /// [currentSchemaVersion].
  factory CycleTemplateModel.fromEntity(
    CycleTemplate template,
  ) => CycleTemplateModel(
    schemaVersion: currentSchemaVersion,
    incomeLines: template.incomeLines.map(IncomeLineModel.fromEntity).toList(),
    budgetLines: template.budgetLines.map(BudgetLineModel.fromEntity).toList(),
    defaultAllocations: template.defaultAllocations
        .map(AllocationModel.fromEntity)
        .toList(),
  );

  /// Versi skema saat ini.
  static const currentSchemaVersion = 1;

  /// Versi skema dokumen ini.
  final int schemaVersion;

  /// Baris pemasukan tetap.
  final List<IncomeLineModel> incomeLines;

  /// Baris anggaran tetap.
  final List<BudgetLineModel> budgetLines;

  /// Persentase alokasi investasi bawaan.
  final List<AllocationModel> defaultAllocations;

  /// Menulis [CycleTemplateModel] ke JSON.
  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'incomeLines': incomeLines.map((l) => l.toJson()).toList(),
    'budgetLines': budgetLines.map((l) => l.toJson()).toList(),
    'defaultAllocations': defaultAllocations.map((a) => a.toJson()).toList(),
  };

  /// Mengubah model jadi entitas domain.
  CycleTemplate toEntity() => CycleTemplate(
    incomeLines: incomeLines.map((l) => l.toEntity()).toList(),
    budgetLines: budgetLines.map((l) => l.toEntity()).toList(),
    defaultAllocations: defaultAllocations.map((a) => a.toEntity()).toList(),
  );
}
