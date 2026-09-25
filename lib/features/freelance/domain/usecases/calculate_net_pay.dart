import 'package:saldough/features/freelance/domain/entities/deduction_amount.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_rule.dart';
import 'package:saldough/features/freelance/domain/entities/net_pay_breakdown.dart';

/// Menghitung gaji bersih dari total jam kerja, tarif per jam, dan potongan
/// sebuah proyek freelance. Dart murni, tidak menyentuh penyimpanan — bisa
/// diuji tanpa Flutter (lihat ARCHITECTURE_OVERVIEW.md bagian "Pengujian").
///
/// Potongan persentase selalu dihitung dari gaji kotor, bukan dari nilai
/// berjalan setelah potongan sebelumnya (DOMAIN_MODEL.md). `netPay` dihitung
/// dari nominal potongan yang belum dibulatkan — membulatkan potongan lebih
/// dulu bisa meleset satu rupiah (kasus nyata: Rp3.117.500 dengan pajak
/// 2,5% harus menghasilkan Rp3.039.563, bukan Rp3.039.562).
///
/// Dipindahkan dari `shared/income` di T-3.1. Parameternya sengaja nilai
/// mentah, bukan entitas proyek, karena `FreelanceProject` baru lahir di
/// T-5.1.
final class CalculateNetPay {
  /// Menghitung rincian gaji untuk [totalHours] jam pada [hourlyRate] sen per
  /// jam, dipotong [deductionRules].
  NetPayBreakdown call({
    required int totalHours,
    required int hourlyRate,
    List<DeductionRule> deductionRules = const [],
  }) {
    final grossPay = totalHours * hourlyRate;
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
