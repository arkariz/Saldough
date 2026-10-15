import 'dart:async';

import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/app_update/data/remote_config_gateway.dart';
import 'package:saldough/features/app_update/domain/entities/app_version.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';
import 'package:saldough/features/app_update/domain/repositories/release_notes_source.dart';
import 'package:saldough/features/app_update/domain/services/release_note_parser.dart';

const _cacheKey = StorageKey(namespace: 'app_update', name: 'notes');

/// [ReleaseNotesSource] di atas Remote Config dengan salinan lokal
/// (ADR-039 §3.3 butir 4): rantai nilai aktif SDK → salinan lokal → kosong.
///
/// Hanya entri sampai versi yang berjalan yang disalin, supaya catatan rilis
/// yang gagal terbit tidak tersimpan. Dokumen salinan: `{entries: {nama
/// parameter: isi JSON}}`; entri yang rusak diabaikan, bukan menggagalkan.
final class ReleaseNotesRepositoryImpl with RepositoryGuard implements ReleaseNotesSource {
  /// Membuat [ReleaseNotesRepositoryImpl].
  const ReleaseNotesRepositoryImpl({required this._gateway, required this._storage});

  final RemoteConfigGateway _gateway;
  final KeyValueStorage _storage;

  StoredValue<Map<String, String>> get _cache => StoredValue<Map<String, String>>.json(
    key: _cacheKey,
    fromJson: (json) {
      final entries = json['entries'];
      if (entries is! Map<String, dynamic>) throw const FormatException('Salinan catatan tidak valid');
      return {
        for (final e in entries.entries)
          if (e.value is String) e.key: e.value as String,
      };
    },
    toJson: (entries) => {'schemaVersion': 1, 'entries': entries},
    storage: _storage,
  );

  @override
  Stream<void> get changes => _gateway.updates;

  @override
  Future<Either<Failure, ReleaseNotesSnapshot>> load({required AppVersion running, bool refresh = true}) =>
      guard(() async {
        if (refresh) {
          try {
            await _gateway.fetchAndActivate();
          } on Object {
            // Luring atau gagal: pakai nilai aktif dan salinan lokal (B-5).
          }
        }
        final cached = await _readCache();
        final merged = {...cached, ..._gateway.noteValues()};
        final entries = <ReleaseKey, ReleaseNote>{};
        for (final MapEntry(key: name, value: json) in merged.entries) {
          final key = parseReleaseKey(name);
          if (key == null) continue;
          final note = parseReleaseNote(key, json);
          if (note != null) entries[key] = note;
        }
        await _writeCache(entries, running);
        return ReleaseNotesSnapshot(entries: entries, serverRead: _gateway.hasFetched);
      });

  Future<Map<String, String>> _readCache() async {
    try {
      return await _cache.read() ?? const {};
    } on Failure {
      return const {};
    } on FormatException {
      return const {};
    }
  }

  Future<void> _writeCache(Map<ReleaseKey, ReleaseNote> entries, AppVersion running) async {
    final current = (build: running.build, patch: running.patch);
    final installed = {
      for (final note in entries.values)
        if (compareReleaseKeys(note.key, current) <= 0) releaseNoteKeyName(note.key): encodeReleaseNote(note),
    };
    try {
      await _cache.write(installed);
    } on Object {
      // Salinan hanya pengaman; gagal menulis tidak boleh mengganggu.
    }
  }
}
