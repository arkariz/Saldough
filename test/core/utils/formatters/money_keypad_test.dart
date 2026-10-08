import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';

/// Papan angka CATAT (T-14.5): teks nominal sesudah tiap tombol.
void main() {
  String type(List<String> keys, {String from = ''}) => keys.fold(from, applyMoneyKey);

  group('IDR (tanpa desimal)', () {
    setUp(() => ActiveCurrency.notifier.value = AppCurrency.idr);

    test('digit dan 000 diformat dengan pemisah ribuan', () {
      expect(type(['4', '5', '000']), '45.000');
      expect(type(['1', '000', '000']), '1.000.000');
    });

    test('nol di depan diabaikan', () {
      expect(type(['0']), '');
      expect(type(['0', '000', '5']), '5');
    });

    test('hapus satu digit, sampai kosong', () {
      expect(type([moneyKeyBackspace], from: '45.000'), '4.500');
      expect(type([moneyKeyBackspace, moneyKeyBackspace], from: '45'), '');
      expect(type([moneyKeyBackspace]), '');
    });

    test('pemisah desimal ditolak', () {
      expect(type([moneyKeyDecimal], from: '45'), '45');
    });

    test('lebih dari 12 digit ditolak', () {
      expect(type(['0', '0'], from: '1.000.000.000'), '100.000.000.000');
      expect(type(['1'], from: '100.000.000.000'), '100.000.000.000');
      expect(type(['000'], from: '100.000.000.000'), '100.000.000.000');
    });

    test('hasilnya dibaca parseMoneyInput sebagai sen', () {
      expect(parseMoneyInput(type(['7', '5', '000'])), 7500000);
    });
  });

  group('USD (dua desimal)', () {
    setUp(() => ActiveCurrency.notifier.value = AppCurrency.usd);
    tearDown(() => ActiveCurrency.notifier.value = AppCurrency.idr);

    test('desimal paling banyak dua angka; hapus menelusuri balik', () {
      final typed = type(['1', '2', moneyKeyDecimal, '5', '0', '9']);
      expect(parseMoneyInput(typed), 1250);
      expect(type([moneyKeyBackspace, moneyKeyBackspace, moneyKeyBackspace], from: typed), '12');
    });

    test('desimal di awal menjadi 0', () {
      expect(parseMoneyInput(type([moneyKeyDecimal, '5'])), 50);
    });
  });
}
