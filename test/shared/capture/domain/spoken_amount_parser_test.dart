import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/capture/capture.dart';

const NumberLexicon _id = NumberLexicon.indonesian;
const NumberLexicon _en = NumberLexicon.english;

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
      // Regresi verifikasi M1 (F2).
      'satu setengah juta': 1500000,
      'dua setengah juta': 2500000,
      'satu koma lima juta': 1500000,
      'nol koma lima juta': 500000,
      'kopi 25 ribu 2 gelas': 25000,
      'rokok tiga puluh ribu dua bungkus': 30000,
      'dua ribu lima ratus': 2500,
      'dua ratus ribu lima ratus': 200500,
      'satu juta lima ratus': 1000500,
      'seribu lima ratus': 1500,
      'sejuta lima ratus ribu': 1500000,
      'dua belas ribu lima ratus': 12500,
      'Rp 1.250.000,-': 1250000,
      'IDR 50,000.00': 50000,
      'jam 12 makan 20 ribu': 20000,
      'vitamin k 50 ribu': 50000,
      'Transfer Rp50.000 berhasil. Ref 202609301234567890123456': 50000,
    };
    for (final MapEntry(key: text, value: units) in cases.entries) {
      test('"$text" -> $units', () {
        final result = SpokenAmountParser.parse(text, lexicon: _id);
        expect(result.issue, isNull);
        expect(result.sen, sen(units));
      });
    }
  });

  test('frasa nominal dikutip persis dari teks', () {
    expect(SpokenAmountParser.parse('tadi makan siang 35 ribu pakai BCA', lexicon: _id).amount!.text, '35 ribu');
    expect(SpokenAmountParser.parse('Makan Siang Dua Puluh Lima Ribu', lexicon: _id).amount!.text, 'Dua Puluh Lima Ribu');
  });

  group('tidak menebak', () {
    test('dua nominal bersatuan', () {
      expect(SpokenAmountParser.parse('kopi 25 ribu roti 15 ribu', lexicon: _id).issue, SpokenAmountIssue.multiple);
      expect(SpokenAmountParser.parse('500 ribu 1 juta', lexicon: _id).issue, SpokenAmountIssue.multiple);
    });

    test('angka tanpa satuan', () {
      expect(SpokenAmountParser.parse('parkir 5', lexicon: _id).issue, SpokenAmountIssue.withoutUnit);
    });

    test('"5,000" bisa ribuan atau desimal', () {
      expect(SpokenAmountParser.parse('kopi 5,000', lexicon: _id).issue, SpokenAmountIssue.ambiguous);
    });

    test('tanpa nominal', () {
      expect(SpokenAmountParser.parse('tadi belanja', lexicon: _id).issue, SpokenAmountIssue.missing);
      expect(SpokenAmountParser.parse('barusan beli kopi sebelum meeting', lexicon: _id).issue, SpokenAmountIssue.missing);
    });

    test('nominal raksasa tidak meluap diam-diam (F2)', () {
      for (final text in ['Rp 99.999.999.999.999.999', '999999999999999 juta', '5000 miliar']) {
        final result = SpokenAmountParser.parse(text, lexicon: _id);
        expect(result.sen == null || result.sen! > 0, isTrue, reason: '$text -> ${result.sen}');
        expect(result.sen, isNull, reason: text);
      }
    });

    test('deret digit panjang tidak melempar (F3)', () {
      expect(() => SpokenAmountParser.parse('No rek 12345678901234567890123 saldo', lexicon: _id), returnsNormally);
      expect(SpokenAmountParser.parse('No rek 12345678901234567890123', lexicon: _id).issue, SpokenAmountIssue.missing);
    });

    test('desimal lebih dari 4 angka diragukan', () {
      expect(SpokenAmountParser.parse('kopi 1,123456 juta', lexicon: _id).issue, SpokenAmountIssue.ambiguous);
    });

    test('mata uang lain', () {
      expect(SpokenAmountParser.parse('dapat 10 dolar', lexicon: _id).issue, SpokenAmountIssue.foreignCurrency);
      expect(SpokenAmountParser.parse('lunch 10 dollars', currencyCode: 'USD', lexicon: _id).issue, isNull);
      expect(SpokenAmountParser.parse('Rp50.000', currencyCode: 'USD', lexicon: _id).issue, SpokenAmountIssue.foreignCurrency);
    });
  });

  group('angka polos per mata uang (ADR-029 §3.3)', () {
    int? idr(String text) => SpokenAmountParser.parse(text, lexicon: _id).sen;

    test('IDR: angka polos mulai 100 langsung jadi nominal', () {
      expect(idr('parkir 2000'), sen(2000));
      expect(idr('beli kopi 5000'), sen(5000));
      expect(idr('fotokopi 500'), sen(500));
      expect(idr('beli 2 kopi 9000'), sen(9000));
    });

    test('nominal bersatuan menang atas angka polos', () {
      expect(idr('beli 100 lembar kertas 20 ribu'), sen(20000));
    });

    test('dua angka polos ragu; angka kecil tetap tanpa satuan', () {
      expect(SpokenAmountParser.parse('25000 15000', lexicon: _id).issue, SpokenAmountIssue.multiple);
      expect(SpokenAmountParser.parse('parkir 5', lexicon: _id).issue, SpokenAmountIssue.withoutUnit);
    });

    test('mata uang tanpa batas: angka polos tetap disorot', () {
      final result = SpokenAmountParser.parse('coffee 5000', lexicon: _en, currencyCode: 'USD');
      expect(result.issue, SpokenAmountIssue.withoutUnit);
    });
  });

  group('bahasa Inggris (ADR-029 §3.1)', () {
    const cases = {
      'lunch thirty five thousand': 35000,
      'two hundred and fifty thousand': 250000,
      'twelve thousand five hundred': 12500,
      'one and a half million': 1500000,
      'half a million': 500000,
      'one point five million': 1500000,
      'coffee 25k': 25000,
      'paid 5,000 for parking': 5000,
      'five grand': 5000,
    };
    for (final MapEntry(key: text, value: units) in cases.entries) {
      test('"$text" -> $units', () {
        final result = SpokenAmountParser.parse(text, lexicon: _en);
        expect(result.issue, isNull);
        expect(result.sen, sen(units));
      });
    }

    test('pemisah ribuan ikut bahasa', () {
      expect(SpokenAmountParser.parse('35.000', lexicon: _en).issue, SpokenAmountIssue.ambiguous);
      expect(SpokenAmountParser.parse('5,000', lexicon: _id).issue, SpokenAmountIssue.ambiguous);
    });

    test('"a" dan "and" di luar bilangan bukan bagian nominal', () {
      final result = SpokenAmountParser.parse('a coffee and a bagel 12 thousand', lexicon: _en);
      expect(result.sen, sen(12000));
      expect(result.amount!.text, '12 thousand');
    });
  });

  test('leksikon netral hanya membaca digit', () {
    expect(SpokenAmountParser.parse('dua puluh ribu', lexicon: NumberLexicon.neutral).issue, SpokenAmountIssue.missing);
    expect(SpokenAmountParser.parse('Rp1.500.000', lexicon: NumberLexicon.neutral).sen, sen(1500000));
    expect(SpokenAmountParser.parse('25k', lexicon: NumberLexicon.neutral).sen, sen(25000));
  });

  test('posisi frasa dicatat', () {
    final found = SpokenAmountParser.findAll('makan 25 ribu', lexicon: _id).single;
    expect((found.start, found.end), (6, 13));
  });
}
