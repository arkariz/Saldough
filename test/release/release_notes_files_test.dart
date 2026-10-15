import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';
import 'package:saldough/features/app_update/domain/services/release_note_parser.dart';

/// Berkas `release_notes/<build>-<patch>.json` (ADR-039 §3.3): bentuk dan
/// aturan penulisan catatan Apa yang baru. Pemeriksaan yang sama dijalankan
/// CI sebelum build (T-20.6).
void main() {
  final files = [
    for (final entity in Directory('release_notes').listSync())
      if (entity is File && RegExp(r'^\d+-\d+\.json$').hasMatch(entity.uri.pathSegments.last)) entity,
  ];

  final pubspec = File('pubspec.yaml').readAsStringSync();
  final versionLine = RegExp(r'^version:\s*(\S+)\+(\d+)', multiLine: true).firstMatch(pubspec)!;
  final pubspecVersion = versionLine.group(1)!;
  final pubspecBuild = int.parse(versionLine.group(2)!);

  test('ada berkas catatan untuk build di pubspec.yaml (rilis wajib bercatatan)', () {
    expect(
      files.any((f) => f.uri.pathSegments.last == '$pubspecBuild-0.json'),
      isTrue,
      reason: 'release_notes/$pubspecBuild-0.json belum ada',
    );
  });

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    group(name, () {
      final match = RegExp(r'^(\d+)-(\d+)\.json$').firstMatch(name)!;
      final key = (build: int.parse(match.group(1)!), patch: int.parse(match.group(2)!));
      final raw = file.readAsStringSync();
      final note = parseReleaseNote(key, raw);

      test('bentuk sah dan memuat paling sedikit satu butir', () {
        expect(note, isNotNull, reason: 'JSON tidak sah');
        expect(note!.noteCount, greaterThanOrEqualTo(1), reason: 'catatan wajib untuk setiap build');
      });

      test('paling banyak 3 butir, kategori dikenal dan tidak ganda', () {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final categories = [
          for (final g in decoded['groups'] as List<dynamic>) (g as Map<String, dynamic>)['category'],
        ];
        expect(categories.toSet().length, categories.length, reason: 'satu kelompok per kategori');
        for (final c in categories) {
          expect(NoteCategory.fromSlug(c as String), isNotNull, reason: 'kategori "$c" tidak dikenal');
        }
        expect(note!.noteCount, lessThanOrEqualTo(3));
      });

      test('id dan en terisi; teks id tanpa tanda seru, "Anda", "patch", "tambalan", "bug"', () {
        final banned = RegExp(r'!|\b(Anda|patch|tambalan|bug)\b', caseSensitive: false);
        for (final group in note!.groups) {
          for (final item in group.notes) {
            expect(item.id, isNotEmpty);
            expect(item.en, isNotEmpty);
            expect(banned.hasMatch(item.id), isFalse, reason: 'dilarang di "${item.id}"');
            expect(item.en.contains('!'), isFalse, reason: 'tanda seru di "${item.en}"');
          }
        }
      });

      test('nama versi sama dengan pubspec.yaml untuk build yang sama', () {
        if (key.build == pubspecBuild) expect(note!.version, pubspecVersion);
      });
    });
  }
}
