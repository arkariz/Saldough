import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
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

  group('AppMoneyFormatter.format mata uang lain (ADR-025)', () {
    void useCurrency(AppCurrency currency) {
      ActiveCurrency.notifier.value = currency;
      addTearDown(() => ActiveCurrency.notifier.value = AppCurrency.idr);
    }

    test('USD selalu dua desimal, pemisah mengikuti bahasa Indonesia', () {
      useCurrency(AppCurrency.usd);
      expect(AppMoneyFormatter.format(123456), r'$1.234,56');
      expect(AppMoneyFormatter.format(5000), r'$50,00');
      expect(AppMoneyFormatter.format(0), r'$0,00');
    });

    test('USD berbahasa Inggris memakai koma ribuan dan titik desimal', () async {
      useCurrency(AppCurrency.usd);
      await LocaleSettings.setLocale(AppLocale.en);
      addTearDown(() => LocaleSettings.setLocale(AppLocale.id));
      expect(AppMoneyFormatter.format(123456), r'$1,234.56');
    });

    test('USD negatif tanpa pembulatan, tanda minus U+2212', () {
      useCurrency(AppCurrency.usd);
      expect(AppMoneyFormatter.format(-150), r'−$1,50');
      expect(AppMoneyFormatter.format(-1), r'−$0,01');
    });

    test('JPY tanpa desimal, dibulatkan setengah ke atas seperti IDR', () {
      useCurrency(AppCurrency.jpy);
      expect(AppMoneyFormatter.format(123450), '¥1.235');
      expect(AppMoneyFormatter.format(-150), '−¥1');
    });

    test('IDR berbahasa Inggris memakai koma ribuan', () async {
      await LocaleSettings.setLocale(AppLocale.en);
      addTearDown(() => LocaleSettings.setLocale(AppLocale.id));
      expect(AppMoneyFormatter.format(1583956300), 'Rp15,839,563');
    });

    test('parameter currency hanya menimpa satu panggilan', () {
      expect(AppMoneyFormatter.format(5000000, currency: AppCurrency.usd), r'$50.000,00');
      expect(AppMoneyFormatter.format(5000000), 'Rp50.000');
    });
  });
}
