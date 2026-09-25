import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_amount.dart';

/// Hasil `CalculateNetPay` — rincian gaji kotor, tiap potongan, dan gaji
/// bersih (FR-FRL-003).
final class NetPayBreakdown extends Equatable {
  /// Membuat [NetPayBreakdown].
  const NetPayBreakdown({
    required this.grossPay,
    required this.deductions,
    required this.netPay,
  });

  /// Gaji kotor dalam sen — `totalHours × hourlyRate`.
  final int grossPay;

  /// Rincian tiap potongan yang diterapkan.
  final List<DeductionAmount> deductions;

  /// Gaji bersih dalam sen — `grossPay − Σ deductions.amount`, dihitung dari
  /// nominal potongan yang BELUM dibulatkan (lihat catatan pembulatan di
  /// DOMAIN_MODEL.md bagian "Freelance").
  final int netPay;

  @override
  List<Object?> get props => [grossPay, deductions, netPay];
}
