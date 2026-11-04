import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/notification_capture/domain/services/negative_shapes.dart';

const _shapesKey = StorageKey(namespace: 'capture', name: 'negative_shapes');

/// [NegativeShapeStore] di atas [KeyValueStorage]: satu dokumen
/// `{schemaVersion, items: [{packageName, template}]}`.
final class NegativeShapeStoreImpl with RepositoryGuard implements NegativeShapeStore {
  /// Membuat [NegativeShapeStoreImpl] di atas [_storage].
  const NegativeShapeStoreImpl({required this._storage});

  /// Versi skema dokumen.
  static const schemaVersion = 1;

  final KeyValueStorage _storage;

  StoredValue<List<NegativeShape>> get _value => StoredValue<List<NegativeShape>>.json(
    key: _shapesKey,
    fromJson: (json) => [
      for (final item in json['items'] as List? ?? const [])
        if (item case {'packageName': final String packageName, 'template': final String template})
          NegativeShape(packageName: packageName, template: template),
    ],
    toJson: (shapes) => {
      'schemaVersion': schemaVersion,
      'items': [
        for (final s in shapes) {'packageName': s.packageName, 'template': s.template},
      ],
    },
    storage: _storage,
  );

  @override
  Future<Either<Failure, List<NegativeShape>>> load() => guard(() async => await _value.read() ?? const []);

  @override
  Future<Either<Failure, Unit>> save(List<NegativeShape> shapes) => guardVoid(() => _value.write(shapes));
}
