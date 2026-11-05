import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/notification_capture/domain/services/approved_shapes.dart';

const _shapesKey = StorageKey(namespace: 'capture', name: 'approved_shapes');

/// [ApprovedShapeStore] di atas [KeyValueStorage]: satu dokumen
/// `{schemaVersion, items: [{packageName, template, approvedAt, amounts, autoCount}]}`.
final class ApprovedShapeStoreImpl with RepositoryGuard implements ApprovedShapeStore {
  /// Membuat [ApprovedShapeStoreImpl] di atas [_storage].
  const ApprovedShapeStoreImpl({required this._storage});

  /// Versi skema dokumen.
  static const schemaVersion = 1;

  final KeyValueStorage _storage;

  StoredValue<List<ApprovedShape>> get _value => StoredValue<List<ApprovedShape>>.json(
    key: _shapesKey,
    fromJson: (json) => [
      for (final item in json['items'] as List? ?? const [])
        if (item case {
          'packageName': final String packageName,
          'template': final String template,
          'approvedAt': final String approvedAt,
        })
          ApprovedShape(
            packageName: packageName,
            template: template,
            approvedAt: DateTime.parse(approvedAt),
            amounts: [
              for (final a in (item['amounts'] as List? ?? const []))
                if (a is int) a,
            ],
            autoCount: item['autoCount'] as int? ?? 0,
          ),
    ],
    toJson: (shapes) => {
      'schemaVersion': schemaVersion,
      'items': [
        for (final s in shapes)
          {
            'packageName': s.packageName,
            'template': s.template,
            'approvedAt': s.approvedAt.toIso8601String(),
            'amounts': s.amounts,
            'autoCount': s.autoCount,
          },
      ],
    },
    storage: _storage,
  );

  @override
  Future<Either<Failure, List<ApprovedShape>>> load() => guard(() async => await _value.read() ?? const []);

  @override
  Future<Either<Failure, Unit>> save(List<ApprovedShape> shapes) => guardVoid(() => _value.write(shapes));
}
