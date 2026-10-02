// Port kecil milik `plan` untuk data fitur lain (ADR-0009), diimplementasikan
// adapter di fitur penyedia dan dikawat di `RootModule`.
// ignore_for_file: one_member_abstracts

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Satu anggaran yang terhitung di bulan keuangan: pos pengeluarannya untuk
/// uang nganggur (§7.2) dan sisanya untuk perkiraan (§7.4).
final class PlanBudget extends Equatable {
  /// Membuat [PlanBudget].
  const PlanBudget({required this.walletId, required this.periodEnd, required this.lines});

  /// Dompet anggaran.
  final String walletId;

  /// Akhir periode (eksklusif).
  final DateTime periodEnd;

  /// Pos pengeluaran (tanpa pos transfer, KT-R14).
  final List<BudgetPlanLine> lines;

  /// Sisa yang belum terpakai, tidak negatif, untuk perkiraan.
  int get remaining => lines.fold(0, (sum, line) => sum + (line.planned > line.spent ? line.planned - line.spent : 0));

  @override
  List<Object?> get props => [walletId, periodEnd, lines];
}

/// Anggaran tidak diarsipkan yang tanggal mulainya jatuh di bulan keuangan
/// `from <= d < until`, beserta terpakainya per pos.
abstract interface class PlanBudgetSource {
  /// Lihat [PlanBudgetSource].
  Future<Either<Failure, List<PlanBudget>>> budgetsStartingIn(DateTime from, DateTime until);
}

/// Pembayaran freelance yang belum dibayar, sebagai pemasukan belum pasti
/// (KT-R6), bernominal gaji bersih dan bertanggal perkiraannya.
abstract interface class PlanFreelanceSource {
  /// Lihat [PlanFreelanceSource].
  Future<Either<Failure, List<UncertainIncome>>> unpaid();
}
