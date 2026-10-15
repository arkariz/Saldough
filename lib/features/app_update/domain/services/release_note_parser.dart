import 'dart:convert';

import 'package:saldough/features/app_update/domain/entities/release_note.dart';

/// Awalan nama parameter Remote Config entri catatan (ADR-039 §3.3).
const releaseNoteKeyPrefix = 'whats_new_';

/// `(build, patch)` dari nama parameter `whats_new_<build>_<patch>`, atau
/// `null` bila bukan nama entri catatan.
ReleaseKey? parseReleaseKey(String name) {
  if (!name.startsWith(releaseNoteKeyPrefix)) return null;
  final parts = name.substring(releaseNoteKeyPrefix.length).split('_');
  if (parts.length != 2) return null;
  final build = int.tryParse(parts[0]);
  final patch = int.tryParse(parts[1]);
  if (build == null || patch == null || build < 0 || patch < 0) return null;
  return (build: build, patch: patch);
}

/// Nama parameter untuk [key].
String releaseNoteKeyName(ReleaseKey key) => '$releaseNoteKeyPrefix${key.build}_${key.patch}';

/// Mengurai isi satu entri catatan; `null` bila bentuknya tidak sah. Kategori
/// tak dikenal tetap dibawa (tanpa label), butir tanpa teks dibuang.
ReleaseNote? parseReleaseNote(ReleaseKey key, String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) return null;
    final version = decoded['version'];
    final groups = decoded['groups'];
    if (version is! String || version.isEmpty || groups is! List<dynamic>) return null;
    final parsed = <NoteGroup>[];
    for (final raw in groups) {
      if (raw is! Map<String, dynamic>) return null;
      final category = raw['category'];
      final notes = raw['notes'];
      if (category is! String || notes is! List<dynamic>) return null;
      final items = <LocalizedNote>[];
      for (final note in notes) {
        if (note is! Map<String, dynamic>) return null;
        final id = note['id'];
        final en = note['en'];
        if (id is! String || en is! String) return null;
        if (id.trim().isEmpty && en.trim().isEmpty) continue;
        items.add(LocalizedNote(id: id.trim(), en: en.trim()));
      }
      if (items.isNotEmpty) parsed.add(NoteGroup(category: NoteCategory.fromSlug(category), notes: items));
    }
    return ReleaseNote(build: key.build, patch: key.patch, version: version, groups: parsed);
  } on FormatException {
    return null;
  }
}

/// Isi entri [note] sebagai JSON, untuk salinan lokal.
String encodeReleaseNote(ReleaseNote note) => jsonEncode({
  'version': note.version,
  'groups': [
    for (final group in note.groups)
      {
        'category': group.category?.slug ?? 'unknown',
        'notes': [
          for (final item in group.notes) {'id': item.id, 'en': item.en},
        ],
      },
  ],
});
