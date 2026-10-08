import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';

/// Setelan tersimpan [AmountVisibility]-nya aplikasi.
abstract interface class AmountVisibilityRepository {
  /// `true` kalau nominal disembunyikan; belum pernah diatur berarti `false`.
  Future<Either<Failure, bool>> load();

  /// Menyimpan setelan.
  Future<Either<Failure, Unit>> save({required bool hidden});
}

const _hiddenKey = StorageKey(namespace: 'settings', name: 'hideAmounts');

/// [AmountVisibilityRepository] di atas [KeyValueStorage]: satu dokumen
/// `{schemaVersion, hidden}`.
final class AmountVisibilityRepositoryImpl with RepositoryGuard implements AmountVisibilityRepository {
  /// Membuat [AmountVisibilityRepositoryImpl] di atas [_storage].
  const AmountVisibilityRepositoryImpl({required this._storage});

  /// Versi skema dokumen.
  static const schemaVersion = 1;

  final KeyValueStorage _storage;

  StoredValue<bool> get _store => StoredValue<bool>.json(
    key: _hiddenKey,
    fromJson: (json) => json['hidden'] as bool? ?? false,
    toJson: (hidden) => {'schemaVersion': schemaVersion, 'hidden': hidden},
    storage: _storage,
  );

  @override
  Future<Either<Failure, bool>> load() => guard(() async => await _store.read() ?? false);

  @override
  Future<Either<Failure, Unit>> save({required bool hidden}) => guardVoid(() => _store.write(hidden));
}
