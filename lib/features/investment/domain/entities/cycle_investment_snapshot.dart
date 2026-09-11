import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/investment/domain/entities/allocation_percentage.dart';

/// Potret rencana investasi sebuah siklus, dibaca/ditulis lewat
/// `CycleInvestmentGateway` — bentuk transport lintas fitur, bukan salinan
/// `InvestmentPlan` milik `cycle` (ADR-0009).
final class CycleInvestmentSnapshot extends Equatable {
  /// Membuat [CycleInvestmentSnapshot].
  const CycleInvestmentSnapshot({
    required this.cycleId,
    required this.remainder,
    required this.returnDeposit,
    required this.allocations,
    required this.isClosed,
  });

  /// Identitas siklus, format `YYYY-MM`.
  final String cycleId;

  /// Sisa siklus (`totalIncome - totalBudget`), SEBELUM [returnDeposit].
  final int remainder;

  /// Tambahan dana dalam sen. Nol kalau tidak ada.
  final int returnDeposit;

  /// Persentase alokasi per pos yang sudah tersimpan di siklus ini. Kosong
  /// berarti belum dialokasikan.
  final List<AllocationPercentage> allocations;

  /// True kalau siklus ini sudah ditutup — `saveAllocationPlan` menolak
  /// menyunting siklus yang sudah ditutup (ADR-0008).
  final bool isClosed;

  /// `remainder + returnDeposit` — dasar perhitungan `CalculateAllocations`.
  int get investmentBudget => remainder + returnDeposit;

  @override
  List<Object?> get props => [cycleId, remainder, returnDeposit, allocations, isClosed];
}
