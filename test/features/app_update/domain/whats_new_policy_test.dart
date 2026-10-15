import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/app_version.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';
import 'package:saldough/features/app_update/domain/services/whats_new_policy.dart';

/// Lembar Apa yang baru (APP_UPDATE F3, B-10–B-12, kasus uji emas QA).
void main() {
  ReleaseNote note(int build, int patch, String version, {int count = 3}) => ReleaseNote(
    build: build,
    patch: patch,
    version: version,
    groups: [
      NoteGroup(
        category: NoteCategory.newFeature,
        notes: [for (var i = 0; i < count; i++) LocalizedNote(id: '$version/$patch #$i', en: '$version/$patch #$i')],
      ),
    ],
  );

  Map<ReleaseKey, ReleaseNote> entries(List<ReleaseNote> notes) => {for (final n in notes) n.key: n};

  AppVersion running(int build, int patch, [String name = '0.6.0']) =>
      AppVersion(name: name, build: build, patch: patch);

  AppUpdateMemory seen(int build, int patch) => AppUpdateMemory.empty.see(build, patch);

  WhatsNewDecision decide(
    AppVersion version,
    AppUpdateMemory memory,
    List<ReleaseNote> notes, {
    bool serverRead = true,
  }) => decideWhatsNew(running: version, memory: memory, entries: entries(notes), serverRead: serverRead);

  List<ReleaseKey> shown(WhatsNewDecision decision) => [for (final n in (decision as WhatsNewShow).notes) n.key];

  test('pertama: belum ada versi terakhir dilihat, tidak ada lembar', () {
    expect(decide(running(6, 0), AppUpdateMemory.empty, [note(6, 0, '0.5.0')]), isA<WhatsNewNothing>());
  });

  test('6 → 7: lembar versi 7', () {
    final decision = decide(running(7, 0), seen(6, 0), [note(6, 0, '0.5.0'), note(7, 0, '0.6.0')]);
    expect(shown(decision), [(build: 7, patch: 0)]);
  });

  test('pembaruan kecil 0 → 1: lembar pembaruan kecil itu saja', () {
    final decision = decide(running(7, 1), seen(7, 0), [note(7, 0, '0.6.0'), note(7, 1, '0.6.0')]);
    expect(shown(decision), [(build: 7, patch: 1)]);
  });

  test('lompat versi 6 → 9: gabungan, terbaru di atas', () {
    final decision = decide(running(9, 0), seen(6, 0), [
      note(6, 0, '0.5.0'),
      note(7, 0, '0.6.0'),
      note(9, 0, '0.7.0'),
    ]);
    expect(shown(decision), [(build: 9, patch: 0), (build: 7, patch: 0)]);
  });

  test('gabungan paling banyak 6 butir, dipotong dari bawah (B-12)', () {
    final decision = decide(running(9, 0), seen(6, 0), [note(7, 0, '0.6.0'), note(8, 0, '0.6.5'), note(9, 0, '0.7.0')]);
    final notes = (decision as WhatsNewShow).notes;
    expect(notes.fold(0, (sum, n) => sum + n.noteCount), 6);
    expect(notes.map((n) => n.key), [(build: 9, patch: 0), (build: 8, patch: 0)]);
  });

  test('versi tanpa butir (groups kosong) tidak membuat lembar', () {
    const empty = ReleaseNote(build: 7, patch: 2, version: '0.6.0', groups: []);
    expect(decide(running(7, 2), seen(7, 1), [empty]), isA<WhatsNewNothing>());
  });

  test('rollback atau versi sama: tidak ada lembar', () {
    expect(decide(running(7, 1), seen(7, 2), [note(7, 1, '0.6.0')]), isA<WhatsNewNothing>());
    expect(decide(running(7, 2), seen(7, 2), [note(7, 2, '0.6.0')]), isA<WhatsNewNothing>());
  });

  group('catatan belum terambil (APP_UPDATE §11)', () {
    test('entri versi berjalan belum ada dan server belum terbaca: tunda', () {
      expect(decide(running(7, 0), seen(6, 0), const [], serverRead: false), isA<WhatsNewWait>());
    });

    test('server terbaca tetapi entri memang tidak ada: tidak ada lembar', () {
      expect(decide(running(7, 0), seen(6, 0), const []), isA<WhatsNewNothing>());
    });

    test('salinan lokal sudah memuat entri versi berjalan: tampil walau server belum terbaca', () {
      final decision = decide(running(7, 0), seen(6, 0), [note(7, 0, '0.6.0')], serverRead: false);
      expect(shown(decision), [(build: 7, patch: 0)]);
    });
  });

  test('entri yang lebih baru dari versi berjalan (yatim atau belum dipasang) tidak ikut', () {
    final decision = decide(running(7, 0), seen(6, 0), [note(7, 0, '0.6.0'), note(8, 0, '0.7.0')]);
    expect(shown(decision), [(build: 7, patch: 0)]);
  });

  group('installedNotes', () {
    test('hanya yang sudah terpasang, terbaru di atas', () {
      final list = installedNotes(
        running: running(7, 1),
        entries: entries([note(6, 0, '0.5.0'), note(7, 0, '0.6.0'), note(7, 1, '0.6.0'), note(8, 0, '0.7.0')]),
      );
      expect([for (final n in list) n.key], [(build: 7, patch: 1), (build: 7, patch: 0), (build: 6, patch: 0)]);
    });
  });
}
