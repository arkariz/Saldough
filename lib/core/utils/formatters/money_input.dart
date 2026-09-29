import 'package:flutter/services.dart';
import 'package:saldough/core/currency/active_currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';

final _nonDigits = RegExp('[^0-9]');

/// Keyboard kolom nominal: tombol desimal hanya untuk mata uang berdesimal.
TextInputType get moneyKeyboardType =>
    TextInputType.numberWithOptions(decimal: ActiveCurrency.value.fractionDigits > 0);

/// Apakah [sen] bisa ditulis utuh di kolom nominal mata uang aktif. Mata
/// uang tanpa desimal tidak bisa menampung pecahan sen tersimpan; kolom
/// seperti itu dibiarkan kosong, bukan diisi nilai yang terpotong.
bool isMoneyInputExact(int sen) => ActiveCurrency.value.fractionDigits > 0 || sen % 100 == 0;

/// Teks kolom nominal untuk [sen] (nonnegatif), mis. `500000` sen →
/// `"5.000"` (IDR) atau `"5,000"` (USD, en), dan `12345` → `"123,45"` (USD,
/// id). Desimal ditulis hanya bila tidak nol. Untuk mata uang tanpa desimal,
/// pecahan sen dibuang — periksa [isMoneyInputExact] dulu bila itu penting.
String formatMoneyInput(int sen) {
  final whole = MoneySeparators.groupThousands(sen ~/ 100);
  final cents = sen % 100;
  if (ActiveCurrency.value.fractionDigits == 0 || cents == 0) return whole;
  return '$whole${MoneySeparators.decimal}${cents.toString().padLeft(2, '0')}';
}

/// Membaca balik teks kolom nominal jadi sen, atau `null` kalau kosong,
/// nol, atau negatif. Kolom nominal wajib lewat sini, bukan `int.tryParse`
/// langsung pada teks yang masih berpemisah.
int? parseMoneyInput(String text) {
  final hasFraction = ActiveCurrency.value.fractionDigits > 0;
  final decimalIndex = hasFraction ? text.indexOf(MoneySeparators.decimal) : -1;
  final wholeDigits = (decimalIndex < 0 ? text : text.substring(0, decimalIndex)).replaceAll(_nonDigits, '');
  final fractionDigits = decimalIndex < 0 ? '' : text.substring(decimalIndex + 1).replaceAll(_nonDigits, '');
  if (wholeDigits.isEmpty && fractionDigits.isEmpty) return null;
  final whole = wholeDigits.isEmpty ? 0 : int.tryParse(wholeDigits);
  if (whole == null) return null;
  final cents = fractionDigits.isEmpty ? 0 : int.parse(fractionDigits.padRight(2, '0').substring(0, 2));
  final sen = whole * 100 + cents;
  return sen <= 0 ? null : sen;
}

/// Formatter kolom nominal: menyisipkan pemisah ribuan, dan untuk mata uang
/// berdesimal menerima satu pemisah desimal dengan paling banyak dua angka
/// (ADR-025 §3.4).
///
/// Selalu menaruh kursor di akhir teks — penyederhanaan yang disengaja,
/// bukan kelalaian: kolom ini secara semantik rata kanan (nominal uang),
/// jadi mempertahankan posisi kursor di tengah string tidak berarti apa-apa
/// bagi pemakainya.
class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final decimal = MoneySeparators.decimal;
    final hasFraction = ActiveCurrency.value.fractionDigits > 0;
    var text = newValue.text;

    // Titik dan koma sama-sama berarti "mulai desimal" kalau baru diketik di
    // akhir: di bahasa Indonesia titik juga pemisah ribuan, jadi hanya
    // karakter terakhir yang baru ditambahkan yang bisa dibedakan.
    final typedSeparator =
        hasFraction &&
        !oldValue.text.contains(decimal) &&
        text.length == oldValue.text.length + 1 &&
        (text.endsWith('.') || text.endsWith(','));
    if (typedSeparator) text = '${text.substring(0, text.length - 1)}$decimal';

    final decimalIndex = hasFraction ? text.indexOf(decimal) : -1;
    final wholeDigits = (decimalIndex < 0 ? text : text.substring(0, decimalIndex)).replaceAll(_nonDigits, '');
    final String formatted;
    if (decimalIndex < 0) {
      if (wholeDigits.isEmpty) return TextEditingValue.empty;
      formatted = MoneySeparators.groupThousands(int.parse(wholeDigits));
    } else {
      var fraction = text.substring(decimalIndex + 1).replaceAll(_nonDigits, '');
      if (fraction.length > 2) fraction = fraction.substring(0, 2);
      final whole = wholeDigits.isEmpty ? 0 : int.parse(wholeDigits);
      formatted = '${MoneySeparators.groupThousands(whole)}$decimal$fraction';
    }
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

/// Label ringkas pilihan cepat [sen]: `10.000` → `+10rb`, `5.000.000` →
/// `+5jt` (id) atau `+10k`, `+5M` (en); nominal yang tidak bulat ribu/juta
/// ditulis penuh (`+500`).
String formatQuickAmount(int sen) {
  final whole = sen ~/ 100;
  final en = LocaleSettings.currentLocale == AppLocale.en;
  if (whole >= 1000000 && whole % 1000000 == 0) return '+${whole ~/ 1000000}${en ? 'M' : 'jt'}';
  if (whole >= 1000 && whole % 1000 == 0) return '+${whole ~/ 1000}${en ? 'k' : 'rb'}';
  return '+${formatMoneyInput(sen)}';
}
