import 'package:saldough/shared/income/domain/deduction_kind.dart';
import 'package:saldough/shared/income/domain/deduction_rule.dart';

/// Model serialisasi [DeductionRule].
final class DeductionRuleModel {
  /// Membuat [DeductionRuleModel].
  const DeductionRuleModel({
    required this.id,
    required this.label,
    required this.kind,
    required this.value,
  });

  /// Membaca [DeductionRuleModel] dari JSON.
  factory DeductionRuleModel.fromJson(Map<String, dynamic> json) => DeductionRuleModel(
        id: json['id'] as String,
        label: json['label'] as String,
        kind: DeductionKind.values.byName(json['kind'] as String),
        value: json['value'] as int,
      );

  /// Membuat model dari entitas domain.
  factory DeductionRuleModel.fromEntity(DeductionRule rule) => DeductionRuleModel(
        id: rule.id,
        label: rule.label,
        kind: rule.kind,
        value: rule.value,
      );

  /// Identitas aturan.
  final String id;

  /// Nama yang tampil.
  final String label;

  /// Jenis potongan.
  final DeductionKind kind;

  /// Untuk `percentage`: nilai per mil. Untuk `fixedAmount`: sen.
  final int value;

  /// Menulis [DeductionRuleModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'kind': kind.name,
        'value': value,
      };

  /// Mengubah model jadi entitas domain.
  DeductionRule toEntity() => DeductionRule(id: id, label: label, kind: kind, value: value);
}
