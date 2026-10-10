import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/utils/formatters/money_expression.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';

/// Kalkulator papan angka Catat (T-8.18): ungkapan sesudah tiap tombol dan
/// hasilnya dalam sen.
void main() {
  String type(List<String> keys, {String from = ''}) => keys.fold(from, applyMoneyExpressionKey);

  group('IDR (tanpa desimal)', () {
    setUp(() => ActiveCurrency.notifier.value = AppCurrency.idr);

    test('operand berpemisah ribuan dan operator bersimbol', () {
      expect(type(['1', '0', '000', moneyKeyAdd, '5', '000']), '10.000 + 5.000');
      expect(type(['2', moneyKeySubtract, '1', moneyKeyMultiply, '3', moneyKeyDivide, '4']), '2 − 1 × 3 ÷ 4');
    });

    test('operator di awal ditolak; operator berturut-turut mengganti yang terakhir', () {
      expect(type([moneyKeyAdd]), '');
      expect(type(['5', moneyKeyAdd, moneyKeyMultiply]), '5 ×');
    });

    test('hapus memotong operand terakhir, lalu operatornya', () {
      expect(type([moneyKeyBackspace], from: '10.000 + 55'), '10.000 + 5');
      expect(type([moneyKeyBackspace], from: '10.000 + 5'), '10.000 +');
      expect(type([moneyKeyBackspace], from: '10.000 +'), '10.000');
      expect(hasMoneyOperator('10.000'), isFalse);
      expect(hasMoneyOperator('10.000 +'), isTrue);
    });

    test('batas digit berlaku per operand', () {
      expect(type(['1'], from: '1 + 100.000.000.000'), '1 + 100.000.000.000');
    });

    test('× dan ÷ didahulukan dari + dan −', () {
      expect(evaluateMoneyExpression('10.000 + 5.000 × 2').sen, 2000000);
      expect(evaluateMoneyExpression('100.000 − 20.000 ÷ 4 × 2').sen, 9000000);
      expect(evaluateMoneyExpression('25.000 × 3').sen, 7500000);
    });

    test('operator di akhir diabaikan; tanpa operator sama dengan parseMoneyInput', () {
      expect(evaluateMoneyExpression('10.000 +').sen, 1000000);
      expect(evaluateMoneyExpression('45.000').sen, parseMoneyInput('45.000'));
      expect(evaluateMoneyExpression(''), (sen: null, error: null));
    });

    test('pembagian dibulatkan ke rupiah utuh, setengah ke atas', () {
      expect(evaluateMoneyExpression('100.000 ÷ 3').sen, 3333300);
      expect(evaluateMoneyExpression('5 ÷ 2').sen, 300);
      expect(evaluateMoneyExpression('1 ÷ 3 × 3').sen, 100);
    });

    test('hasil nol atau negatif tidak sah', () {
      expect(evaluateMoneyExpression('10.000 − 10.000').error, MoneyExpressionError.notPositive);
      expect(evaluateMoneyExpression('5 − 10').error, MoneyExpressionError.notPositive);
      expect(evaluateMoneyExpression('1 ÷ 3').error, MoneyExpressionError.notPositive);
    });

    test('hasil melewati 12 digit tidak sah', () {
      expect(evaluateMoneyExpression('999.999.999.999 + 1').error, MoneyExpressionError.tooLarge);
      expect(evaluateMoneyExpression('999.999.999.999 × 999.999.999.999').error, MoneyExpressionError.tooLarge);
      expect(evaluateMoneyExpression('999.999.999.998 + 1').sen, 99999999999900);
    });
  });

  group('USD (dua desimal)', () {
    setUp(() => ActiveCurrency.notifier.value = AppCurrency.usd);
    tearDown(() => ActiveCurrency.notifier.value = AppCurrency.idr);

    test('operand desimal dan pembulatan ke sen', () {
      expect(type(['1', '2', moneyKeyDecimal, '5', moneyKeyMultiply, '2']), '12,5 × 2');
      expect(evaluateMoneyExpression('12,5 × 2').sen, 2500);
      expect(evaluateMoneyExpression('10 ÷ 3').sen, 333);
      expect(evaluateMoneyExpression('0,05 ÷ 2').sen, 3);
    });

    test('bagi nol tidak sah', () {
      expect(type(['1', moneyKeyDivide, moneyKeyDecimal]), '1 ÷ 0,');
      expect(evaluateMoneyExpression('1 ÷ 0,').error, MoneyExpressionError.divideByZero);
    });
  });
}
