import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/income/data/income_source_model.dart';
import 'package:saldough/shared/income/domain/income_source.dart';
import 'package:saldough/shared/income/domain/income_source_repository.dart';

const _sourcesKey = StorageKey(namespace: 'income', name: 'sources');

/// Implementasi [IncomeSourceRepository] di atas [KeyValueStorage], mengikuti
/// pola `GoalRepositoryImpl` (ADR-0009): seluruh sumber disimpan sebagai satu
/// dokumen JSON (daftar kecil).
final class IncomeSourceRepositoryImpl with RepositoryGuard implements IncomeSourceRepository {
  /// Membuat [IncomeSourceRepositoryImpl] di atas [_storage].
  const IncomeSourceRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<IncomeSourceModel>> get _store => StoredValue<List<IncomeSourceModel>>.json(
        key: _sourcesKey,
        fromJson: (json) => (json['items'] as List<dynamic>)
            .map((e) => IncomeSourceModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        toJson: (models) => {
          'schemaVersion': IncomeSourceModel.schemaVersion,
          'items': models.map((m) => m.toJson()).toList(),
        },
        storage: _storage,
      );

  @override
  Future<Either<Failure, List<IncomeSource>>> listSources() => guard(() async {
        final models = await _store.read();
        return (models ?? const []).map((m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, IncomeSource?>> getSource(String id) => guard(() async {
        final models = await _store.read() ?? const [];
        return models.where((m) => m.id == id).firstOrNull?.toEntity();
      });

  @override
  Future<Either<Failure, Unit>> saveSource(IncomeSource source) => guardVoid(() async {
        final models = await _store.read() ?? <IncomeSourceModel>[];
        final next = [
          ...models.where((m) => m.id != source.id),
          IncomeSourceModel.fromEntity(source),
        ];
        await _store.write(next);
      });

  @override
  Future<Either<Failure, Unit>> deleteSource(String id) => guardVoid(() async {
        final models = await _store.read() ?? <IncomeSourceModel>[];
        await _store.write(models.where((m) => m.id != id).toList());
      });
}
