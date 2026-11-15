import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/period_book/domain/services/tanuki_lines.dart';
import 'package:saldough/features/period_book/presentation/tanuki_sentences.dart';

/// Kata dan bentuk yang dilarang di teks Tanuki (BP-7, BUKU_PERIODE §9, writing.md).
final RegExp _forbidden = RegExp(
  r'\b(boros|hemat|terlalu|kurang|sayang|hati-hati|wasteful|frugal|too|careless|careful|unfortunately)\b|!|Anda\b',
  caseSensitive: false,
);

const _all = <TanukiLine>[
  TanukiRecords(12),
  TanukiFlow(income: 850000000, expense: 470500000),
  TanukiTopCategory(name: 'Makan', percent: 35),
  TanukiRecurringClear(recorded: 2, skipped: 1),
  TanukiTidy(),
];

void main() {
  for (final locale in [AppLocale.id, AppLocale.en]) {
    test('kalimat Tanuki ${locale.languageCode}: tanpa penilaian, tanda seru, atau Anda', () async {
      await LocaleSettings.setLocale(locale);
      for (final line in [..._all, const TanukiFlow(income: 100, expense: 400000), const TanukiRecords(1)]) {
        for (final sentence in tanukiSentences([line])) {
          expect(sentence, isNotEmpty);
          expect(_forbidden.hasMatch(sentence), isFalse, reason: sentence);
        }
      }
    });
  }

  test('id: kalimat Rani dirakit dari fakta', () async {
    await LocaleSettings.setLocale(AppLocale.id);
    final sentences = tanukiSentences(_all);
    expect(sentences[0], 'Periode ini kamu mencatat 12 transaksi.');
    expect(sentences[1], contains('Pemasukan'));
    expect(sentences[1], contains('sisanya'));
    expect(sentences[2], 'Makan jadi kategori terbesar, 35% dari pengeluaran.');
    expect(sentences[3], 'Semua rutin sudah beres: 2 tercatat, 1 dilewati.');
    expect(sentences[4], 'Semua transaksi punya kategori, jadi angkanya tepat.');
  });

  test('en: bentuk jamak (1 transaction, 12 transactions) dan selisih negatif tidak memakai "left"', () async {
    await LocaleSettings.setLocale(AppLocale.en);
    expect(tanukiSentences([const TanukiRecords(1)]).single, 'This period you recorded 1 transaction.');
    expect(tanukiSentences([const TanukiRecords(12)]).single, 'This period you recorded 12 transactions.');
    final negative = tanukiSentences([const TanukiFlow(income: 100, expense: 400000)]).single;
    expect(negative, isNot(contains('left')));
    expect(negative, contains('difference'));
    await LocaleSettings.setLocale(AppLocale.id);
  });

  test('semua teks book.tanuki di berkas i18n tanpa kata terlarang', () {
    for (final locale in ['id', 'en']) {
      final json = jsonDecode(File('assets/i18n/$locale.i18n.json').readAsStringSync()) as Map<String, dynamic>;
      final values = <String>[];
      void walk(Object? node) {
        if (node is String) values.add(node);
        if (node is Map) node.values.forEach(walk);
      }

      walk((json['book'] as Map<String, dynamic>)['tanuki']);
      expect(values, isNotEmpty);
      for (final v in values) {
        expect(_forbidden.hasMatch(v), isFalse, reason: '$locale: $v');
      }
    }
  });
}
