import 'package:saldough/core/currency/active_currency.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';

/// Tombol tambah papan angka berkalkulator (T-8.18).
const String moneyKeyAdd = 'add';

/// Tombol kurang papan angka berkalkulator.
const String moneyKeySubtract = 'subtract';

/// Tombol kali papan angka berkalkulator.
const String moneyKeyMultiply = 'multiply';

/// Tombol bagi papan angka berkalkulator.
const String moneyKeyDivide = 'divide';

/// Simbol tampilan tiap tombol operator, urut seperti di papan angka.
const Map<String, String> moneyOperatorSymbols = {
  moneyKeyDivide: '÷',
  moneyKeyMultiply: '×',
  moneyKeySubtract: '−',
  moneyKeyAdd: '+',
};

/// Apakah [key] tombol operator.
bool isMoneyOperatorKey(String key) => moneyOperatorSymbols.containsKey(key);

/// Apakah [expression] memuat operator, yaitu sedang menghitung.
bool hasMoneyOperator(String expression) => expression.contains(' ');

List<String> _tokens(String expression) => expression.isEmpty ? <String>[] : expression.split(' ');

/// Ungkapan sesudah tombol [key] ditekan pada [expression].
///
/// Ungkapan adalah operand dan simbol operator berselang-seling, dipisah
/// satu spasi: `10.000 + 5.000`. Digit, `000`, pemisah desimal, dan hapus
/// mengenai operand terakhir lewat [applyMoneyKey], jadi pemisah ribuan dan
/// batas digit sama dengan papan angka biasa. Operator di awal ditolak,
/// operator berturut-turut mengganti yang terakhir, dan hapus sesudah
/// operator membuang operator itu.
String applyMoneyExpressionKey(String expression, String key) {
  final tokens = _tokens(expression);
  final endsWithOperator = tokens.isNotEmpty && tokens.length.isEven;
  if (isMoneyOperatorKey(key)) {
    if (tokens.isEmpty) return expression;
    final symbol = moneyOperatorSymbols[key]!;
    if (endsWithOperator) {
      tokens.last = symbol;
    } else {
      tokens.add(symbol);
    }
    return tokens.join(' ');
  }
  if (key == moneyKeyBackspace && endsWithOperator) return (tokens..removeLast()).join(' ');
  final operand = tokens.isEmpty || endsWithOperator ? '' : tokens.removeLast();
  final next = applyMoneyKey(operand, key);
  return [...tokens, if (next.isNotEmpty) next].join(' ');
}

/// Alasan [evaluateMoneyExpression] tidak menghasilkan nominal.
enum MoneyExpressionError {
  /// Hasilnya nol atau negatif.
  notPositive,

  /// Ada pembagian dengan nol.
  divideByZero,

  /// Bagian bulat hasilnya melewati [moneyKeyMaxWholeDigits].
  tooLarge,
}

/// Hasil [evaluateMoneyExpression]: [sen] terisi bila sah, selain itu
/// [error] (keduanya `null` untuk ungkapan kosong).
typedef MoneyExpressionResult = ({int? sen, MoneyExpressionError? error});

/// Menghitung [expression] jadi sen.
///
/// × dan ÷ didahulukan dari + dan −; operator di akhir diabaikan. Operand
/// × dan ÷ dibaca sebagai angka biasa (`25.000 × 3` = 75.000). Hitungannya
/// eksak dengan pecahan [BigInt], lalu dibulatkan setengah menjauhi nol ke
/// satuan terkecil mata uang aktif — rupiah utuh untuk mata uang tanpa
/// desimal, sen untuk yang berdesimal.
MoneyExpressionResult evaluateMoneyExpression(String expression) {
  final tokens = _tokens(expression);
  if (tokens.isNotEmpty && tokens.length.isEven) tokens.removeLast();
  if (tokens.isEmpty) return (sen: null, error: null);

  var sum = _Fraction.zero;
  var term = _operand(tokens.first);
  var termSign = BigInt.one;
  for (var i = 1; i < tokens.length; i += 2) {
    final value = _operand(tokens[i + 1]);
    switch (tokens[i]) {
      case '×':
        term = term * value;
      case '÷':
        if (value.isZero) return (sen: null, error: MoneyExpressionError.divideByZero);
        term = term / value;
      default:
        sum = sum + term.scaled(termSign);
        term = value;
        termSign = tokens[i] == '−' ? -BigInt.one : BigInt.one;
    }
  }
  sum = sum + term.scaled(termSign);
  if (!sum.isPositive) return (sen: null, error: MoneyExpressionError.notPositive);

  // Satuan terkecil dalam sen: 1 untuk mata uang berdesimal, 100 (satu
  // satuan utama) untuk yang tidak.
  final step = BigInt.from(ActiveCurrency.value.fractionDigits > 0 ? 1 : 100);
  final steps = sum.scaled(BigInt.from(100)).roundDiv(step);
  final sen = steps * step;
  if (sen <= BigInt.zero) return (sen: null, error: MoneyExpressionError.notPositive);
  if (sen ~/ BigInt.from(100) >= BigInt.from(10).pow(moneyKeyMaxWholeDigits)) {
    return (sen: null, error: MoneyExpressionError.tooLarge);
  }
  return (sen: sen.toInt(), error: null);
}

/// Nilai satu operand dalam satuan utama, mis. `"12,50"` → 1250/100.
/// `parseMoneyInput` mengembalikan `null` untuk nol, padahal operand nol
/// tetap dihitung (`÷ 0,0` harus jadi galat bagi nol).
_Fraction _operand(String text) {
  final hundredths = parseMoneyInput(text) ?? 0;
  return _Fraction(BigInt.from(hundredths), BigInt.from(100));
}

/// Pecahan eksak [numerator]/[denominator], penyebut selalu positif.
final class _Fraction {
  _Fraction(this.numerator, this.denominator);

  static final zero = _Fraction(BigInt.zero, BigInt.one);

  final BigInt numerator;
  final BigInt denominator;

  bool get isZero => numerator == BigInt.zero;

  bool get isPositive => numerator > BigInt.zero;

  _Fraction operator +(_Fraction other) => _Fraction(
        numerator * other.denominator + other.numerator * denominator,
        denominator * other.denominator,
      );

  _Fraction operator *(_Fraction other) =>
      _Fraction(numerator * other.numerator, denominator * other.denominator);

  /// Pembagi [other] tidak nol (operand tidak pernah negatif).
  _Fraction operator /(_Fraction other) =>
      _Fraction(numerator * other.denominator, denominator * other.numerator);

  _Fraction scaled(BigInt factor) => _Fraction(numerator * factor, denominator);

  /// Pecahan ini dibagi [divisor] lalu dibulatkan setengah ke atas; hanya
  /// untuk pecahan positif.
  BigInt roundDiv(BigInt divisor) {
    final d = denominator * divisor;
    return (numerator * BigInt.two + d) ~/ (d * BigInt.two);
  }
}
