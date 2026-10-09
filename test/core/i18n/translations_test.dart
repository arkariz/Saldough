import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sapuan teks T-14.12: kunci id/en lengkap dan teks id mengikuti glosarium
/// design system (`writing.md`).
void main() {
  Map<String, String> flatten(Map<String, dynamic> map, [String prefix = '']) => {
    for (final entry in map.entries)
      ...switch (entry.value) {
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
}
