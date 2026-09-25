import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_rule.dart';

/// Hasil hitung satu [DeductionRule] terhadap gaji kotor tertentu — bagian
/// dari [NetPayBreakdown], dipakai untuk menampilkan rincian (FR-FRL-003).
final class DeductionAmount extends Equatable {
  /// Membuat [DeductionAmount].
  const DeductionAmount({required this.rule, required this.amount});

  /// Aturan yang dihitung.
  final DeductionRule rule;

  /// Nominal potongan dalam sen, BELUM dibulatkan ke rupiah — lihat catatan
  /// pembulatan di [NetPayBreakdown].
  final int amount;

  @override
  List<Object?> get props => [rule, amount];
}
