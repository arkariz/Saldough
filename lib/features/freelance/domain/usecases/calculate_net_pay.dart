import 'package:saldough/features/freelance/domain/entities/deduction_amount.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_rule.dart';
import 'package:saldough/features/freelance/domain/entities/net_pay_breakdown.dart';

/// Menghitung gaji bersih dari gaji kotor dan potongan sebuah pembayaran
/// freelance. Dart murni, tidak menyentuh penyimpanan — bisa diuji tanpa
/// Flutter (lihat ARCHITECTURE_OVERVIEW.md bagian "Pengujian").
///
/// Potongan persentase selalu dihitung dari gaji kotor, bukan dari nilai
/// berjalan setelah potongan sebelumnya (DOMAIN_MODEL.md). `netPay` dihitung
/// dari nominal potongan yang belum dibulatkan — membulatkan potongan lebih
/// dulu bisa meleset satu rupiah (kasus nyata: Rp3.117.500 dengan pajak
/// 2,5% harus menghasilkan Rp3.039.563, bukan Rp3.039.562).
///
/// Menerima gaji kotor langsung, bukan jam dan tarif, karena entri dalam
/// satu pembayaran boleh bertarif berbeda (ADR-019). Gaji kotor adalah
/// `Σ WorklogEntry.earnedAmount`.
final class CalculateNetPay {
  /// Membuat [CalculateNetPay].
  const CalculateNetPay();

  /// Menghitung rincian gaji untuk [grossPay] sen, dipotong [deductionRules].
  NetPayBreakdown call({required int grossPay, List<DeductionRule> deductionRules = const []}) {
    final deductions = [
      for (final rule in deductionRules)
        DeductionAmount(
          rule: rule,
          amount: rule.kind == .percentage ? grossPay * rule.value ~/ 1000 : rule.value,
        ),
    ];
    final totalDeductions = deductions.fold(0, (sum, d) => sum + d.amount);
    return NetPayBreakdown(
      grossPay: grossPay,
      deductions: deductions,
      netPay: grossPay - totalDeductions,
    );
  }
}
