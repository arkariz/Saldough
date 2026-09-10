import 'package:saldough/features/cycle/domain/entities/cycle_totals.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';

/// Menghitung `totalIncome`, `totalBudget`, dan `remainder` sebuah
/// [MonthlyCycle]. Dart murni, tidak menyentuh penyimpanan — bisa diuji
/// tanpa Flutter (lihat ARCHITECTURE_OVERVIEW.md bagian "Pengujian").
final class CalculateCycleTotals {
  /// Menghitung total untuk [cycle].
  CycleTotals call(MonthlyCycle cycle) {
    final totalIncome = cycle.incomeLines.fold(0, (sum, line) => sum + line.amount);
    final totalBudget = cycle.budgetLines.fold(0, (sum, line) => sum + line.amount);
    return CycleTotals(
      totalIncome: totalIncome,
      totalBudget: totalBudget,
      remainder: totalIncome - totalBudget,
    );
  }
}
