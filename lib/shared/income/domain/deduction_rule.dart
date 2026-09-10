import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/income/domain/deduction_kind.dart';

/// Satu aturan potongan pada `IncomeSource` bertipe freelance, misalnya
/// `Pajak` atau `jajan`. Lihat DOMAIN_MODEL.md bagian "Sumber pemasukan dan
/// jam kerja".
final class DeductionRule extends Equatable {
  /// Membuat [DeductionRule].
  const DeductionRule({
    required this.id,
    required this.label,
    required this.kind,
    required this.value,
  });

  /// Identitas aturan.
  final String id;

  /// Nama yang tampil, misalnya `"Pajak"`.
  final String label;

  /// Jenis potongan.
  final DeductionKind kind;

  /// Untuk [DeductionKind.percentage]: nilai **per mil** (perseribu) dari
  /// gaji kotor — 2,5% tersimpan sebagai `25`, bukan `2` atau `2.5` (field
  /// ini `int`). Untuk [DeductionKind.fixedAmount]: nominal dalam sen.
  final int value;

  /// Salinan [DeductionRule] dengan field yang disebutkan diganti.
  DeductionRule copyWith({String? label, DeductionKind? kind, int? value}) {
    return DeductionRule(
      id: id,
      label: label ?? this.label,
      kind: kind ?? this.kind,
      value: value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [id, label, kind, value];
}
