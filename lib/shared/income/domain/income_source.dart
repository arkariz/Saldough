import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/income/domain/deduction_rule.dart';
import 'package:saldough/shared/income/domain/income_source_kind.dart';

/// Definisi sumber pemasukan yang berlaku lintas bulan, bukan nominal per
/// bulan (misalnya `Gaji Menul`, `Gaji Koko`). Lihat DOMAIN_MODEL.md bagian
/// "Sumber pemasukan dan jam kerja".
final class IncomeSource extends Equatable {
  /// Membuat [IncomeSource].
  ///
  /// Melempar [ArgumentError] kalau `kind` bernilai
  /// [IncomeSourceKind.fixedSalary] tapi [fixedAmount] tidak diisi, atau
  /// [IncomeSourceKind.hourlyFreelance] tapi [hourlyRate] tidak diisi.
  IncomeSource({
    required this.id,
    required this.name,
    required this.kind,
    this.fixedAmount,
    this.hourlyRate,
    this.deductionRules = const [],
  }) {
    if (kind == .fixedSalary && fixedAmount == null) {
      throw ArgumentError.value(
        fixedAmount,
        'fixedAmount',
        'Wajib diisi kalau kind bernilai IncomeSourceKind.fixedSalary.',
      );
    }
    if (kind == .hourlyFreelance && hourlyRate == null) {
      throw ArgumentError.value(
        hourlyRate,
        'hourlyRate',
        'Wajib diisi kalau kind bernilai IncomeSourceKind.hourlyFreelance.',
      );
    }
  }

  /// Identitas sumber.
  final String id;

  /// Nama, misalnya `"Gaji Menul"`.
  final String name;

  /// Jenis sumber.
  final IncomeSourceKind kind;

  /// Nominal tetap dalam sen. Wajib terisi kalau [kind] bernilai
  /// [IncomeSourceKind.fixedSalary].
  final int? fixedAmount;

  /// Tarif per jam dalam sen. Wajib terisi kalau [kind] bernilai
  /// [IncomeSourceKind.hourlyFreelance]. Data, bukan konstanta kode — lihat
  /// `.claude/AGENT_CONTEXT.md` bagian nilai seed (Rp72.500 untuk
  /// `Gaji Menul`).
  final int? hourlyRate;

  /// Potongan yang berlaku. Kosong untuk sumber selain freelance.
  final List<DeductionRule> deductionRules;

  /// Salinan [IncomeSource] dengan field yang disebutkan diganti.
  IncomeSource copyWith({
    String? name,
    int? fixedAmount,
    int? hourlyRate,
    List<DeductionRule>? deductionRules,
  }) {
    return IncomeSource(
      id: id,
      name: name ?? this.name,
      kind: kind,
      fixedAmount: fixedAmount ?? this.fixedAmount,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      deductionRules: deductionRules ?? this.deductionRules,
    );
  }

  @override
  List<Object?> get props => [id, name, kind, fixedAmount, hourlyRate, deductionRules];
}
