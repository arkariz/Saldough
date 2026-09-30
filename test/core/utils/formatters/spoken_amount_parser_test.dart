import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/utils/formatters/spoken_amount_parser.dart';

/// Nominal lisan ke `int` sen (ADR-027 §3.3, riset §6 dan §10).
void main() {
  /// Sen dari satuan utama (ADR-025 §3.1: sen = satuan x 100).
  int sen(int units) => units * 100;

  group('nominal yakin', () {
    const cases = {
      'makan 25 ribu': 25000,
      'parkir 5 ribu': 5000,
      'gaji 10 juta': 10000000,
      'tadi ngopi 25k': 25000,
      'top up GoPay 100k': 100000,
      '5rb': 5000,
      '1 juta': 1000000,
      '1,5 juta': 1500000,
      '1.5jt': 1500000,
      '1.500.000': 1500000,
      '35.000': 35000,
      'dua puluh lima ribu': 25000,
      'makan siang tiga puluh lima ribu': 35000,
      'bayar listrik dua ratus lima puluh ribu': 250000,
      'gaji masuk dua belas juta': 12000000,
      'isi bensin seratus ribu': 100000,
      'beli shampoo dan sabun total tujuh puluh dua ribu': 72000,
      'satu juta lima ratus ribu': 1500000,
      '1 juta 500 ribu': 1500000,
      'seribu': 1000,
      'setengah juta': 500000,
      'goceng': 5000,
      'Rp35.000,00 dari BCA': 35000,
      'Rp 35.000': 35000,
      'sebelas ribu': 11000,
      'beli dua kopi lima puluh ribu': 50000,
    };
    for (final MapEntry(key: text, value: units) in cases.entries) {
      test('"$text" -> $units', () {
        final result = SpokenAmountParser.parse(text);
        expect(result.issue, isNull);
        expect(result.sen, sen(units));
      });
    }
  });

  test('frasa nominal dikutip persis dari teks', () {
    expect(SpokenAmountParser.parse('tadi makan siang 35 ribu pakai BCA').amount!.text, '35 ribu');
    expect(SpokenAmountParser.parse('Makan Siang Dua Puluh Lima Ribu').amount!.text, 'Dua Puluh Lima Ribu');
  });

  group('tidak menebak', () {
    test('dua nominal bersatuan', () {
      expect(SpokenAmountParser.parse('kopi 25 ribu roti 15 ribu').issue, SpokenAmountIssue.multiple);
      expect(SpokenAmountParser.parse('500 ribu 1 juta').issue, SpokenAmountIssue.multiple);
    });

    test('angka tanpa satuan', () {
      expect(SpokenAmountParser.parse('parkir 5').issue, SpokenAmountIssue.withoutUnit);
    });

    test('"5,000" bisa ribuan atau desimal', () {
      expect(SpokenAmountParser.parse('kopi 5,000').issue, SpokenAmountIssue.ambiguous);
    });

    test('tanpa nominal', () {
      expect(SpokenAmountParser.parse('tadi belanja').issue, SpokenAmountIssue.missing);
      expect(SpokenAmountParser.parse('barusan beli kopi sebelum meeting').issue, SpokenAmountIssue.missing);
    });

    test('mata uang lain', () {
      expect(SpokenAmountParser.parse('dapat 10 dolar').issue, SpokenAmountIssue.foreignCurrency);
      expect(SpokenAmountParser.parse('lunch 10 dollars', currencyCode: 'USD').issue, isNull);
      expect(SpokenAmountParser.parse('Rp50.000', currencyCode: 'USD').issue, SpokenAmountIssue.foreignCurrency);
    });
  });
}
