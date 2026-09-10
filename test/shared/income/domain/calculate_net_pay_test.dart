import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/income/income.dart';

void main() {
  group('CalculateNetPay', () {
    final calculate = CalculateNetPay();

    IncomeSource sourceWithTax(int hourlyRateSen) => IncomeSource(
          id: 'gaji-menul',
          name: 'Gaji Menul',
          kind: IncomeSourceKind.hourlyFreelance,
          hourlyRate: hourlyRateSen,
          deductionRules: const [
            DeductionRule(id: 'pajak', label: 'Pajak', kind: DeductionKind.percentage, value: 25),
          ],
        );

    // Lima kasus nyata dari MANUAL_PROCESS_ANALYSIS.md (pajak 2,5% konsisten
    // di seluruh tujuh bulan yang punya data) — lihat T-3.3. `totalHours` di
    // sini bersifat sintetis (tarif per jam bukan bagian dari catatan
    // historis, cuma `hourlyRate` hasil × `totalHours` yang perlu pas dengan
    // gaji kotor nyata), tapi gaji kotor, potongan, dan gaji bersihnya nyata.
    test('Rp7.350.000 dengan pajak 2,5% (pembagian genap, tanpa pembulatan)', () {
      final result = calculate(totalHours: 1, source: sourceWithTax(735000000));
      expect(result.grossPay, 735000000);
      expect(result.deductions.single.amount, 18375000);
      expect(result.netPay, 716625000);
    });

    test('Rp1.740.000 dengan pajak 2,5% (pembagian genap, tanpa pembulatan)', () {
      final result = calculate(totalHours: 1, source: sourceWithTax(174000000));
      expect(result.grossPay, 174000000);
      expect(result.deductions.single.amount, 4350000);
      expect(result.netPay, 169650000);
    });

    test('Rp2.682.500 dengan pajak 2,5% (dibulatkan dari 67.062,5 di spreadsheet)', () {
      final result = calculate(totalHours: 1, source: sourceWithTax(268250000));
      expect(result.grossPay, 268250000);
      expect(result.deductions.single.amount, 6706250);
      expect(result.netPay, 261543750);
    });

    test('Rp3.117.500 dengan pajak 2,5% menghasilkan Rp3.039.563, bukan Rp3.039.562', () {
      // ⚠ Kasus kritis: membulatkan potongan (ke Rp77.938) lebih dulu sebelum
      // mengurangi dari gaji kotor menghasilkan Rp3.039.562 — meleset satu
      // rupiah dari jawaban benar. Di sini potongan TIDAK dibulatkan sebelum
      // dikurangi (311750000 × 25 ~/ 1000 = 7793750 sen, pas, tanpa sisa).
      final result = calculate(totalHours: 1, source: sourceWithTax(311750000));
      expect(result.grossPay, 311750000);
      expect(result.deductions.single.amount, 7793750);
      expect(result.netPay, 303956250);
    });

    test('Rp1.087.500 dengan pajak 2,5% (dibulatkan dari 27.187,5 di spreadsheet)', () {
      final result = calculate(totalHours: 1, source: sourceWithTax(108750000));
      expect(result.grossPay, 108750000);
      expect(result.deductions.single.amount, 2718750);
      expect(result.netPay, 106031250);
    });

    test('gaji kotor = totalHours × hourlyRate', () {
      final result = calculate(
        totalHours: 40,
        source: IncomeSource(id: 's', name: 'S', kind: IncomeSourceKind.hourlyFreelance, hourlyRate: 7250000),
      );
      expect(result.grossPay, 290000000);
      expect(result.netPay, 290000000);
    });

    test('potongan fixedAmount tidak bergantung pada gaji kotor', () {
      final source = IncomeSource(
        id: 's',
        name: 'S',
        kind: IncomeSourceKind.hourlyFreelance,
        hourlyRate: 7250000,
        deductionRules: const [
          DeductionRule(id: 'jajan', label: 'jajan', kind: DeductionKind.fixedAmount, value: 15000000),
        ],
      );
      final result = calculate(totalHours: 40, source: source);
      expect(result.deductions.single.amount, 15000000);
      expect(result.netPay, 275000000);
    });

    test('beberapa potongan selalu dihitung dari gaji kotor yang sama, bukan nilai berjalan', () {
      final source = IncomeSource(
        id: 's',
        name: 'S',
        kind: IncomeSourceKind.hourlyFreelance,
        hourlyRate: 100000000,
        deductionRules: const [
          DeductionRule(id: 'pajak', label: 'Pajak', kind: DeductionKind.percentage, value: 100),
          DeductionRule(id: 'jajan', label: 'jajan', kind: DeductionKind.fixedAmount, value: 5000000),
        ],
      );
      final result = calculate(totalHours: 1, source: source);
      // Kalau potongan kedua dihitung dari nilai SETELAH potongan pertama
      // (bukan dari gaji kotor), hasilnya akan berbeda dari jumlah sederhana
      // ini — rumus di DOMAIN_MODEL.md menegaskan keduanya dari gaji kotor.
      expect(result.deductions[0].amount, 10000000);
      expect(result.deductions[1].amount, 5000000);
      expect(result.netPay, 85000000);
    });
  });
}
