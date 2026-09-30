import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/domain/capture/number_lexicon.dart';
import 'package:saldough/features/record/domain/capture/spoken_date_parser.dart';

/// Tanggal lisan (ADR-029 §3.2). Acuan: Rabu 30 Sep 2026 pukul 12.
void main() {
  final today = DateTime(2026, 9, 30, 12);

  List<SpokenDate> id(String text, {DateTime? at}) => SpokenDateParser.findAll(
    text,
    lexicon: DateLexicon.indonesian,
    numbers: NumberLexicon.indonesian,
    today: at ?? today,
  );

  List<SpokenDate> en(String text, {DateTime? at}) => SpokenDateParser.findAll(
    text,
    lexicon: DateLexicon.english,
    numbers: NumberLexicon.english,
    today: at ?? today,
  );

  DateTime day(int y, int m, int d) => DateTime(y, m, d, 12);

  group('bahasa Indonesia', () {
    final cases = {
      'beli kopi 5000 tanggal 27 september': (day(2026, 9, 27), 'tanggal 27 september'),
      'makan 27 sept': (day(2026, 9, 27), '27 sept'),
      'makan 5 oktober': (day(2025, 10, 5), '5 oktober'),
      'makan 5 okt 2025': (day(2025, 10, 5), '5 okt 2025'),
      'tgl 3 makan': (day(2026, 9, 3), 'tgl 3'),
      'tanggal 31 makan': (day(2026, 8, 31), 'tanggal 31'),
      'makan 27/9': (day(2026, 9, 27), '27/9'),
      'makan 27-9-2026': (day(2026, 9, 27), '27-9-2026'),
      'kemarin makan': (day(2026, 9, 29), 'kemarin'),
      'kemarin lusa makan': (day(2026, 9, 28), 'kemarin lusa'),
      'makan dua hari lalu': (day(2026, 9, 28), 'dua hari lalu'),
      'makan 3 hari yang lalu': (day(2026, 9, 27), '3 hari yang lalu'),
      'hari ini makan': (day(2026, 9, 30), 'hari ini'),
    };
    for (final MapEntry(key: text, value: (date, quote)) in cases.entries) {
      test('"$text"', () {
        final found = id(text).single;
        expect(found.date, date);
        expect(found.text, quote);
        expect(text.substring(found.start, found.end), quote);
      });
    }

    test('tanggal tidak ada atau di masa depan dengan tahun: disebut, tidak sah', () {
      expect(id('makan 31 februari 2026').single.date, isNull);
      expect(id('makan 5 oktober 2026').single.date, isNull);
      expect(id('makan 5 oktober 1999').single.date, isNull);
    });

    test('29 Februari tanpa tahun mundur ke tahun kabisat terakhir', () {
      expect(id('makan 29 februari').single.date, day(2024, 2, 29));
    });

    test('pergantian tahun: "tanggal 31" di awal Januari', () {
      expect(id('tanggal 31', at: DateTime(2027, 1, 5, 12)).single.date, day(2026, 12, 31));
      expect(id('20 desember', at: DateTime(2027, 1, 5, 12)).single.date, day(2026, 12, 20));
    });

    test('bukan tanggal', () {
      expect(id('beli 2-3 kopi 20 ribu'), isEmpty);
      expect(id('makan 25 ribu'), isEmpty);
      expect(id('parkir 5 ribu'), isEmpty);
    });
  });

  group('bahasa Inggris', () {
    final cases = {
      'coffee on September 27th': (day(2026, 9, 27), 'on September 27th'),
      'coffee Sept 27, 2026': (day(2026, 9, 27), 'Sept 27, 2026'),
      'coffee the 27th of September': (day(2026, 9, 27), 'the 27th of September'),
      'coffee 27 September': (day(2026, 9, 27), '27 September'),
      'coffee on the 3rd': (day(2026, 9, 3), 'on the 3rd'),
      'coffee 9/27': (day(2026, 9, 27), '9/27'),
      'coffee yesterday': (day(2026, 9, 29), 'yesterday'),
      'coffee the day before yesterday': (day(2026, 9, 28), 'the day before yesterday'),
      'coffee two days ago': (day(2026, 9, 28), 'two days ago'),
    };
    for (final MapEntry(key: text, value: (date, quote)) in cases.entries) {
      test('"$text"', () {
        final found = en(text).single;
        expect(found.date, date);
        expect(found.text, quote);
      });
    }

    test('"may" dan "the" tanpa angka bukan tanggal', () {
      expect(en('I may buy the coffee 5 dollars'), isEmpty);
      expect(en('the 5 coffees'), isEmpty);
    });
  });
}
