import 'package:saldough/shared/income/data/deduction_rule_model.dart';
import 'package:saldough/shared/income/domain/income_source.dart';
import 'package:saldough/shared/income/domain/income_source_kind.dart';

/// Model serialisasi [IncomeSource].
final class IncomeSourceModel {
  /// Membuat [IncomeSourceModel].
  const IncomeSourceModel({
    required this.id,
    required this.name,
    required this.kind,
    this.fixedAmount,
    this.hourlyRate,
    this.deductionRules = const [],
  });

  /// Membaca [IncomeSourceModel] dari JSON.
  factory IncomeSourceModel.fromJson(Map<String, dynamic> json) => IncomeSourceModel(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: IncomeSourceKind.values.byName(json['kind'] as String),
        fixedAmount: json['fixedAmount'] as int?,
        hourlyRate: json['hourlyRate'] as int?,
        deductionRules: (json['deductionRules'] as List<dynamic>)
            .map((e) => DeductionRuleModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Membuat model dari entitas domain.
  factory IncomeSourceModel.fromEntity(IncomeSource source) => IncomeSourceModel(
        id: source.id,
        name: source.name,
        kind: source.kind,
        fixedAmount: source.fixedAmount,
        hourlyRate: source.hourlyRate,
        deductionRules: source.deductionRules.map(DeductionRuleModel.fromEntity).toList(),
      );

  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  static const schemaVersion = 1;

  /// Identitas sumber.
  final String id;

  /// Nama sumber.
  final String name;

  /// Jenis sumber.
  final IncomeSourceKind kind;

  /// Nominal tetap dalam sen.
  final int? fixedAmount;

  /// Tarif per jam dalam sen.
  final int? hourlyRate;

  /// Aturan potongan.
  final List<DeductionRuleModel> deductionRules;

  /// Menulis [IncomeSourceModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'fixedAmount': fixedAmount,
        'hourlyRate': hourlyRate,
        'deductionRules': deductionRules.map((r) => r.toJson()).toList(),
      };

  /// Mengubah model jadi entitas domain.
  IncomeSource toEntity() => IncomeSource(
        id: id,
        name: name,
        kind: kind,
        fixedAmount: fixedAmount,
        hourlyRate: hourlyRate,
        deductionRules: deductionRules.map((r) => r.toEntity()).toList(),
      );
}
