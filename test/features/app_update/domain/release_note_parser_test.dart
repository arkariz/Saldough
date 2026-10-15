import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';
import 'package:saldough/features/app_update/domain/services/release_note_parser.dart';

/// Berkas catatan berkategori (ADR-039 §3.3).
void main() {
  group('parseReleaseKey', () {
    test('whats_new_<build>_<patch>', () {
      expect(parseReleaseKey('whats_new_7_0'), (build: 7, patch: 0));
      expect(parseReleaseKey('whats_new_12_3'), (build: 12, patch: 3));
    });

    test('nama lain, bentuk salah, atau angka negatif: null', () {
      expect(parseReleaseKey('latest_release_note_id'), isNull);
      expect(parseReleaseKey('whats_new_7'), isNull);
      expect(parseReleaseKey('whats_new_a_b'), isNull);
      expect(parseReleaseKey('whats_new_7_0_id'), isNull);
      expect(parseReleaseKey('whats_new_-1_0'), isNull);
    });

    test('releaseNoteKeyName adalah kebalikannya', () {
      expect(parseReleaseKey(releaseNoteKeyName((build: 9, patch: 2))), (build: 9, patch: 2));
    });
  });

  group('parseReleaseNote', () {
    const key = (build: 7, patch: 0);
    const json = '''
{"version":"0.6.0","groups":[
  {"category":"new","notes":[{"id":"Satu.","en":"One."},{"id":"Dua.","en":"Two."}]},
  {"category":"fixed","notes":[{"id":"Tiga.","en":"Three."}]}]}''';

    test('mengurai versi, kelompok, dan butir sesuai urutan', () {
      final note = parseReleaseNote(key, json)!;
      expect((note.build, note.patch, note.version), (7, 0, '0.6.0'));
      expect([for (final g in note.groups) g.category], [NoteCategory.newFeature, NoteCategory.fixed]);
      expect(note.groups.first.notes.map((n) => n.id), ['Satu.', 'Dua.']);
      expect(note.noteCount, 3);
      expect(note.key, key);
    });

    test('kategori tak dikenal dibawa tanpa kategori, bukan dibuang', () {
      final note = parseReleaseNote(
        key,
        '{"version":"0.6.0","groups":[{"category":"masa_depan","notes":[{"id":"A","en":"A"}]}]}',
      )!;
      expect(note.groups.single.category, isNull);
      expect(note.noteCount, 1);
    });

    test('butir tanpa teks dibuang; kelompok kosong dibuang; groups kosong sah', () {
      final note = parseReleaseNote(
        key,
        '{"version":"0.6.0","groups":[{"category":"new","notes":[{"id":" ","en":""}]}]}',
      )!;
      expect(note.groups, isEmpty);
      expect(note.isEmpty, isTrue);
      expect(parseReleaseNote(key, '{"version":"0.6.0","groups":[]}')!.isEmpty, isTrue);
    });

    test('bentuk tidak sah: null', () {
      expect(parseReleaseNote(key, 'bukan json'), isNull);
      expect(parseReleaseNote(key, '[]'), isNull);
      expect(parseReleaseNote(key, '{"groups":[]}'), isNull);
      expect(parseReleaseNote(key, '{"version":"","groups":[]}'), isNull);
      expect(parseReleaseNote(key, '{"version":"0.6.0"}'), isNull);
      expect(parseReleaseNote(key, '{"version":"0.6.0","groups":[{"category":"new"}]}'), isNull);
      expect(
        parseReleaseNote(key, '{"version":"0.6.0","groups":[{"category":"new","notes":[{"id":1,"en":"x"}]}]}'),
        isNull,
      );
    });

    test('encode lalu parse menghasilkan catatan yang sama', () {
      final note = parseReleaseNote(key, json)!;
      expect(parseReleaseNote(key, encodeReleaseNote(note)), note);
    });
  });

  test('LocalizedNote memilih bahasa, Inggris sebagai cadangan', () {
    const note = LocalizedNote(id: 'Satu.', en: 'One.');
    expect(note.text(english: false), 'Satu.');
    expect(note.text(english: true), 'One.');
    expect(const LocalizedNote(id: '', en: 'One.').text(english: false), 'One.');
  });
}
