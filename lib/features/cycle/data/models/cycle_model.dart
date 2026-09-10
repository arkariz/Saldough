import 'package:saldough/features/cycle/data/models/budget_line_model.dart';
import 'package:saldough/features/cycle/data/models/income_line_model.dart';
import 'package:saldough/features/cycle/data/models/investment_plan_model.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';

/// Model serialisasi [MonthlyCycle], disimpan satu dokumen per siklus
/// (ADR-0002).
final class CycleModel {
  /// Membuat [CycleModel].
  const CycleModel({
    required this.schemaVersion,
    required this.id,
    required this.incomeLines,
    required this.budgetLines,
    required this.investmentPlan,
    this.closedAt,
  });

  /// Membaca [CycleModel] dari JSON.
  factory CycleModel.fromJson(Map<String, dynamic> json) => CycleModel(
        schemaVersion: json['schemaVersion'] as int,
        id: json['id'] as String,
        incomeLines: (json['incomeLines'] as List<dynamic>)
            .map((e) => IncomeLineModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        budgetLines: (json['budgetLines'] as List<dynamic>)
            .map((e) => BudgetLineModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        investmentPlan:
            InvestmentPlanModel.fromJson(json['investmentPlan'] as Map<String, dynamic>),
        closedAt: json['closedAt'] == null ? null : DateTime.parse(json['closedAt'] as String),
      );

  /// Membuat model dari entitas domain, siap disimpan dengan
  /// [currentSchemaVersion].
  factory CycleModel.fromEntity(MonthlyCycle cycle) => CycleModel(
        schemaVersion: currentSchemaVersion,
        id: cycle.id,
        incomeLines: cycle.incomeLines.map(IncomeLineModel.fromEntity).toList(),
        budgetLines: cycle.budgetLines.map(BudgetLineModel.fromEntity).toList(),
        investmentPlan: InvestmentPlanModel.fromEntity(cycle.investmentPlan),
        closedAt: cycle.closedAt,
      );

  /// Versi skema saat ini.
  static const currentSchemaVersion = 1;

  /// Versi skema dokumen ini.
  final int schemaVersion;

  /// Identitas siklus, format `YYYY-MM`.
  final String id;

  /// Baris di bagian pemasukan.
  final List<IncomeLineModel> incomeLines;

  /// Baris di bagian anggaran.
  final List<BudgetLineModel> budgetLines;

  /// Rencana pembagian sisa.
  final InvestmentPlanModel investmentPlan;

  /// Terisi saat siklus dikunci.
  final DateTime? closedAt;

  /// Menulis [CycleModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'incomeLines': incomeLines.map((l) => l.toJson()).toList(),
        'budgetLines': budgetLines.map((l) => l.toJson()).toList(),
        'investmentPlan': investmentPlan.toJson(),
        'closedAt': closedAt?.toIso8601String(),
      };

  /// Mengubah model jadi entitas domain. Baris `rollUp` memakai nominal
  /// tersimpan apa adanya — `CycleRepositoryImpl` yang menimpanya dengan
  /// hasil `RollUpResolver` setelah ini dipanggil.
  MonthlyCycle toEntity() => MonthlyCycle(
        id: id,
        incomeLines: incomeLines.map((l) => l.toEntity()).toList(),
        budgetLines: budgetLines.map((l) => l.toEntity()).toList(),
        investmentPlan: investmentPlan.toEntity(),
        closedAt: closedAt,
      );
}
