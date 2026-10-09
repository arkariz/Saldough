import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';

/// Sapuan teks T-14.12: kunci id/en lengkap dan teks id mengikuti glosarium
/// design system (`writing.md`).
void main() {
  const pluralForms = {'zero', 'one', 'two', 'few', 'many', 'other'};

  // Bentuk jamak slang (`one`/`other`) satu kunci: id cukup `other`.
  Map<String, String> flatten(Map<String, dynamic> map, [String prefix = '']) => {
    for (final entry in map.entries)
      ...switch (entry.value) {
        final Map<String, dynamic> child when child.keys.every(pluralForms.contains) => {
          '$prefix${entry.key}': child.values.join(' | '),
        },
        final Map<String, dynamic> child => flatten(child, '$prefix${entry.key}.'),
        final value => {'$prefix${entry.key}': '$value'},
      },
  };

  Map<String, String> load(String lang) =>
      flatten(jsonDecode(File('assets/i18n/$lang.i18n.json').readAsStringSync()) as Map<String, dynamic>);

  final id = load('id');
  final en = load('en');

  test('kunci id dan en sama persis', () {
    expect(id.keys.toSet().difference(en.keys.toSet()), isEmpty, reason: 'ada di id, tidak di en');
    expect(en.keys.toSet().difference(id.keys.toSet()), isEmpty, reason: 'ada di en, tidak di id');
  });

  test('teks id tanpa istilah terlarang glosarium', () {
    final banned = RegExp(
      r'\b(kas|log|mutasi|netto|inventaris|kantong|entri|piutang|tangkapan|Anda)\b',
      caseSensitive: false,
    );
    final hits = {
      for (final MapEntry(:key, :value) in id.entries)
        if (banned.hasMatch(value)) key: value,
    };
    expect(hits, isEmpty);
  });

  test('teks id tanpa label langkah "//", tanpa tanda seru, tanpa CATAT kapital', () {
    final hits = {
      for (final MapEntry(:key, :value) in id.entries)
        if (value.contains('//') || value.contains('!') || value.contains('CATAT')) key: value,
    };
    expect(hits, isEmpty);
  });

  test('teks en tanpa jamak "(s)": pakai bentuk jamak slang (QA PR #43 F9, F19)', () async {
    final hits = {
      for (final MapEntry(:key, :value) in en.entries)
        if (value.contains('(s)')) key: value,
    };
    expect(hits, isEmpty);

    await LocaleSettings.setLocale(AppLocale.en);
    addTearDown(() => LocaleSettings.setLocale(AppLocale.id));
    expect(t.recurring.reminderSoonTitle(n: 1), 'In 1 day');
    expect(t.recurring.reminderSoonTitle(n: 3), 'In 3 days');
    expect(t.recurring.reminderLine(n: 1), endsWith('1 day before'));
  });
}
