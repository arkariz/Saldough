import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';

void main() {
  void useCurrency(AppCurrency currency) {
    ActiveCurrency.notifier.value = currency;
    addTearDown(() => ActiveCurrency.notifier.value = AppCurrency.idr);
  }

  Future<void> useEnglish() async {
    await LocaleSettings.setLocale(AppLocale.en);
    addTearDown(() => LocaleSettings.setLocale(AppLocale.id));
  }

  /// Mengetik [typed] satu karakter per satu lewat [MoneyInputFormatter].
  String type(String typed) {
    final formatter = MoneyInputFormatter();
    var value = TextEditingValue.empty;
    for (final char in typed.split('')) {
      final next = TextEditingValue(text: '${value.text}$char');
      value = formatter.formatEditUpdate(value, next);
    }
    return value.text;
  }

  group('IDR (bawaan, tanpa desimal)', () {
    test('format dan parse berbasis sen', () {
      expect(formatMoneyInput(500000000), '5.000.000');
      expect(parseMoneyInput('5.000.000'), 500000000);
    });

    test('kosong, nol, dan teks tanpa angka berarti null', () {
      expect(parseMoneyInput(''), isNull);
      expect(parseMoneyInput('0'), isNull);
      expect(parseMoneyInput('abc'), isNull);
    });

    test('mengetik koma diabaikan, tidak memulai desimal', () {
      expect(type('12,5'), '125');
    });

    test('pecahan sen tidak bisa ditulis utuh', () {
      expect(isMoneyInputExact(150), isFalse);
      expect(isMoneyInputExact(100), isTrue);
    });

    test('label pilihan cepat bahasa Indonesia dan Inggris', () async {
      expect(formatQuickAmount(1000000), '+10rb');
      expect(formatQuickAmount(500000000), '+5jt');
      await useEnglish();
      expect(formatQuickAmount(1000000), '+10k');
      expect(formatQuickAmount(500000000), '+5M');
    });
  });

  group('USD (dua desimal)', () {
    test('mengetik desimal dengan koma di bahasa Indonesia', () {
      useCurrency(AppCurrency.usd);
      expect(type('1234,5'), '1.234,5');
      expect(parseMoneyInput('1.234,5'), 123450);
    });

    test('titik yang diketik di akhir juga memulai desimal di bahasa Indonesia', () {
      useCurrency(AppCurrency.usd);
      expect(type('12.'), '12,');
      expect(type('12.75'), '12,75');
    });

    test('paling banyak dua angka desimal', () {
      useCurrency(AppCurrency.usd);
      expect(type('9,999'), '9,99');
    });

    test('bahasa Inggris: koma ribuan, titik desimal', () async {
      useCurrency(AppCurrency.usd);
      await useEnglish();
      expect(type('1234.56'), '1,234.56');
      expect(parseMoneyInput('1,234.56'), 123456);
    });

    test('formatMoneyInput hanya menulis desimal bila tidak nol', () {
      useCurrency(AppCurrency.usd);
      expect(formatMoneyInput(5000), '50');
      expect(formatMoneyInput(5005), '50,05');
      expect(isMoneyInputExact(5005), isTrue);
    });

    test('desimal saja tanpa angka depan tetap terbaca', () {
      useCurrency(AppCurrency.usd);
      expect(type(',5'), '0,5');
      expect(parseMoneyInput('0,5'), 50);
    });

    test('pilihan cepat kecil ditulis penuh', () {
      useCurrency(AppCurrency.usd);
      expect(formatQuickAmount(500), '+5');
    });
  });
}
