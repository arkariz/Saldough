import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/app_version.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';

/// Paling banyak butir di lembar yang menggabungkan beberapa versi (B-12).
const maxCombinedNotes = 6;

/// Keputusan lembar Apa yang baru (APP_UPDATE F3, B-10–B-12).
sealed class WhatsNewDecision {
  const WhatsNewDecision();
}

/// Tidak ada lembar; versi terakhir dilihat boleh dimajukan.
final class WhatsNewNothing extends WhatsNewDecision {
  /// Membuat [WhatsNewNothing].
  const WhatsNewNothing();
}

/// Catatan belum bisa dipastikan (belum terambil): tunda, jangan majukan
/// versi terakhir dilihat (APP_UPDATE §11).
final class WhatsNewWait extends WhatsNewDecision {
  /// Membuat [WhatsNewWait].
  const WhatsNewWait();
}

/// Tampilkan lembar dengan [notes] (terbaru di atas, paling banyak
/// [maxCombinedNotes] butir).
final class WhatsNewShow extends WhatsNewDecision {
  /// Membuat [WhatsNewShow].
  const WhatsNewShow(this.notes);

  /// Catatan yang ditampilkan.
  final List<ReleaseNote> notes;
}

/// Memutuskan lembar Apa yang baru untuk versi [running] dari [memory] dan
/// [entries].
///
/// Pemasangan pertama (belum ada versi terakhir dilihat) dan rollback
/// (berjalan ≤ terakhir dilihat) tidak menampilkan apa-apa. Entri versi yang
/// berjalan wajib ada (catatan wajib, ADR-039); bila belum ada dan server
/// belum pernah terbaca, lembar ditunda, bukan dilewati.
WhatsNewDecision decideWhatsNew({
  required AppVersion running,
  required AppUpdateMemory memory,
  required Map<ReleaseKey, ReleaseNote> entries,
  required bool serverRead,
}) {
  final lastBuild = memory.lastSeenBuild;
  if (lastBuild == null) return const WhatsNewNothing();
  final last = (build: lastBuild, patch: memory.lastSeenPatch);
  final current = (build: running.build, patch: running.patch);
  if (compareReleaseKeys(current, last) <= 0) return const WhatsNewNothing();
  if (!entries.containsKey(current) && !serverRead) return const WhatsNewWait();
  final fresh = [
    for (final note in entries.values)
      if (!note.isEmpty && compareReleaseKeys(note.key, last) > 0 && compareReleaseKeys(note.key, current) <= 0) note,
  ]..sort((a, b) => compareReleaseKeys(b.key, a.key));
  if (fresh.isEmpty) return const WhatsNewNothing();
  return WhatsNewShow(_limit(fresh, maxCombinedNotes));
}

/// Semua catatan yang sudah terpasang (sampai [running]), terbaru di atas,
/// untuk daftar di Akun.
List<ReleaseNote> installedNotes({required AppVersion running, required Map<ReleaseKey, ReleaseNote> entries}) {
  final current = (build: running.build, patch: running.patch);
  return [
    for (final note in entries.values)
      if (!note.isEmpty && compareReleaseKeys(note.key, current) <= 0) note,
  ]..sort((a, b) => compareReleaseKeys(b.key, a.key));
}

/// Memotong [notes] (terbaru di atas) menjadi paling banyak [max] butir,
/// dari yang paling atas; kelompok dan catatan yang kosong dibuang.
List<ReleaseNote> _limit(List<ReleaseNote> notes, int max) {
  var left = max;
  final out = <ReleaseNote>[];
  for (final note in notes) {
    if (left <= 0) break;
    final groups = <NoteGroup>[];
    for (final group in note.groups) {
      if (left <= 0) break;
      final taken = group.notes.take(left).toList();
      left -= taken.length;
      if (taken.isNotEmpty) groups.add(NoteGroup(category: group.category, notes: taken));
    }
    if (groups.isNotEmpty) {
      out.add(ReleaseNote(build: note.build, patch: note.patch, version: note.version, groups: groups));
    }
  }
  return out;
}
