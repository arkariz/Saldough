import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';

const _splitKey = StorageKey(namespace: 'savings_goal', name: 'split');

/// Persen pembagian terakhir saat menabung ke beberapa tujuan (ADR-048
/// §9.3): `goalId` → persen. Kenyamanan isian milik perangkat, tidak ikut
/// cadangan.
final class GoalSplitMemory with RepositoryGuard {
  /// Membuat [GoalSplitMemory].
  const GoalSplitMemory({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<Map<String, int>> get _store =>
      StoredValue<Map<String, int>>.json(
        key: _splitKey,
        fromJson: (json) => {
          for (final e in (json['percents'] as Map<String, dynamic>).entries)
            e.key: (e.value as num).toInt(),
        },
        toJson: (percents) => {'schemaVersion': 1, 'percents': percents},
        storage: _storage,
      );

  /// Persen terakhir, kosong bila belum pernah.
  Future<Either<Failure, Map<String, int>>> read() =>
      guard(() async => await _store.read() ?? const {});

  /// Menyimpan [percents], menimpa yang lama.
  Future<Either<Failure, Unit>> save(Map<String, int> percents) =>
      guardVoid(() => _store.write(percents));
}
