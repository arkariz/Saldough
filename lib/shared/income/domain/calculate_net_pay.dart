import 'package:saldough/shared/income/domain/deduction_amount.dart';
import 'package:saldough/shared/income/domain/income_source.dart';
import 'package:saldough/shared/income/domain/net_pay_breakdown.dart';

/// Menghitung gaji bersih dari total jam kerja dan sebuah [IncomeSource]
/// bertipe [IncomeSourceKind.hourlyFreelance]. Dart murni, tidak menyentuh
/// penyimpanan — bisa diuji tanpa Flutter (lihat ARCHITECTURE_OVERVIEW.md
/// bagian "Pengujian").
///
/// Potongan persentase selalu dihitung dari gaji kotor, bukan dari nilai
/// berjalan setelah potongan sebelumnya (DOMAIN_MODEL.md). `netPay` dihitung
/// dari nominal potongan yang belum dibulatkan — membulatkan potongan lebih
/// dulu bisa meleset satu rupiah (kasus nyata: Rp3.117.500 dengan pajak
/// 2,5% harus menghasilkan Rp3.039.563, bukan Rp3.039.562).
final class CalculateNetPay {
  /// Menghitung rincian gaji untuk [totalHours] jam dari [source].
  NetPayBreakdown call({required int totalHours, required IncomeSource source}) {
    final grossPay = totalHours * source.hourlyRate!;
    final deductions = [
      for (final rule in source.deductionRules)
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
