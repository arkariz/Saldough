import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/income/domain/deduction_amount.dart';

/// Hasil `CalculateNetPay` — rincian gaji kotor, tiap potongan, dan gaji
/// bersih (FR-INC-003).
final class NetPayBreakdown extends Equatable {
  /// Membuat [NetPayBreakdown].
  const NetPayBreakdown({
    required this.grossPay,
    required this.deductions,
    required this.netPay,
  });

  /// Gaji kotor dalam sen — `totalHours × source.hourlyRate`.
  final int grossPay;

  /// Rincian tiap potongan yang diterapkan.
  final List<DeductionAmount> deductions;

  /// Gaji bersih dalam sen — `grossPay − Σ deductions.amount`, dihitung dari
  /// nominal potongan yang BELUM dibulatkan (lihat catatan pembulatan di
  /// DOMAIN_MODEL.md bagian "Catatan jam dan buku jam").
  final int netPay;

  @override
  List<Object?> get props => [grossPay, deductions, netPay];
}
