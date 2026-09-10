import 'package:dependencies/dependencies.dart';

/// Nilai turunan sebuah `MonthlyCycle` — tidak pernah disimpan, selalu
/// dihitung ulang (lihat DOMAIN_MODEL.md bagian "Siklus bulanan").
final class CycleTotals extends Equatable {
  /// Membuat [CycleTotals].
  const CycleTotals({
    required this.totalIncome,
    required this.totalBudget,
    required this.remainder,
  });

  /// Jumlah seluruh `incomeLines.amount`, dalam sen.
  final int totalIncome;

  /// Jumlah seluruh `budgetLines.amount`, dalam sen.
  final int totalBudget;

  /// `totalIncome - totalBudget`. Boleh negatif — ini bukan kesalahan,
  /// lihat DOMAIN_MODEL.md.
  final int remainder;

  /// True kalau [remainder] negatif.
  bool get isOverBudget => remainder < 0;

  @override
  List<Object?> get props => [totalIncome, totalBudget, remainder];
}
