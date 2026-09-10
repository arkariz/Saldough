import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';

void main() {
  group('AppMoneyFormatter.format', () {
    test('membulatkan 3.039.562,50 sen menjadi Rp3.039.563', () {
      // netPay kotor 3.117.500, pajak 2,5% -> net 3.039.562,50 rupiah.
      // DOMAIN_MODEL.md/TASK_LIST.md T-1.6: kasus wajib.
      expect(AppMoneyFormatter.format(303956250), 'Rp3.039.563');
    });

    test('memformat sisa positif nyata tanpa pecahan', () {
      // remainder 15.839.563 - 13.382.490 = 2.457.073 (utuh, tanpa pecahan).
      expect(AppMoneyFormatter.format(245707300), 'Rp2.457.073');
    });

    test('memformat sisa negatif dengan tanda minus U+2212', () {
      // remainder negatif 8.900.000 - 10.237.042 = -1.337.042 (utuh).
      // Ini kasus regresi: ~/ bawaan Dart memotong ke nol, bukan lantai,
      // sehingga tanpa koreksi _floorDiv hasilnya -1.337.041 — meleset satu
      // rupiah. Lihat komentar di money_formatter.dart.
      expect(AppMoneyFormatter.format(-133704200), '−Rp1.337.042');
    });

    test('membulatkan pecahan setengah rupiah negatif ke atas (lebih besar)', () {
      // -1,5 rupiah dibulatkan setengah ke atas menjadi -1, bukan -2.
      expect(AppMoneyFormatter.format(-150), '−Rp1');
    });

    test('memformat nol', () {
      expect(AppMoneyFormatter.format(0), 'Rp0');
    });

    test('mengelompokkan ribuan dengan titik pada nominal besar', () {
      expect(AppMoneyFormatter.format(1583956300), 'Rp15.839.563');
    });
  });
}
