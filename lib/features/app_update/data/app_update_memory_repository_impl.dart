import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/repositories/app_update_memory_repository.dart';

const _memoryKey = StorageKey(namespace: 'app_update', name: 'memory');

/// Implementasi [AppUpdateMemoryRepository] di atas [KeyValueStorage]: satu
/// dokumen `{schemaVersion, lastSeenBuild, lastSeenPatch, deferredBuild,
/// deferredAt, announcedPatches}`. Bukan data keuangan.
final class AppUpdateMemoryRepositoryImpl with RepositoryGuard implements AppUpdateMemoryRepository {
  /// Membuat [AppUpdateMemoryRepositoryImpl] di atas [_storage].
  const AppUpdateMemoryRepositoryImpl({required this._storage});

  /// Versi skema dokumen.
  static const schemaVersion = 1;

  final KeyValueStorage _storage;

  StoredValue<AppUpdateMemory> get _store => StoredValue<AppUpdateMemory>.json(
    key: _memoryKey,
    fromJson: _fromJson,
    toJson: (memory) => {
      'schemaVersion': schemaVersion,
      'lastSeenBuild': memory.lastSeenBuild,
      'lastSeenPatch': memory.lastSeenPatch,
      'deferredBuild': memory.deferredBuild,
      'deferredAt': memory.deferredAt?.toIso8601String(),
      'announcedPatches': {for (final e in memory.announcedPatches.entries) '${e.key}': e.value},
    },
    storage: _storage,
  );

  static AppUpdateMemory _fromJson(Map<String, dynamic> json) {
    final lastSeenBuild = json['lastSeenBuild'];
    final lastSeenPatch = json['lastSeenPatch'];
    final announced = json['announcedPatches'];
    if ((lastSeenBuild != null && lastSeenBuild is! int) ||
        lastSeenPatch is! int ||
        announced is! Map<String, dynamic>) {
      throw const FormatException('Dokumen ingatan pembaruan tidak valid');
    }
    final deferredAt = json['deferredAt'];
    return AppUpdateMemory(
      lastSeenBuild: lastSeenBuild as int?,
      lastSeenPatch: lastSeenPatch,
      deferredBuild: json['deferredBuild'] as int?,
      deferredAt: deferredAt is String ? DateTime.parse(deferredAt) : null,
      announcedPatches: {for (final e in announced.entries) int.parse(e.key): e.value as int},
    );
  }

  @override
  Future<Either<Failure, AppUpdateMemory>> load() => guard(() async => await _store.read() ?? AppUpdateMemory.empty);

  @override
  Future<Either<Failure, Unit>> save(AppUpdateMemory memory) => guardVoid(() => _store.write(memory));
}
