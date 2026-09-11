import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/cycle/data/models/cycle_template_model.dart';
import 'package:saldough/features/cycle/domain/entities/cycle_template.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_template_repository.dart';

const _templateKey = StorageKey(namespace: 'cycle', name: 'template');

/// Implementasi [CycleTemplateRepository] di atas [KeyValueStorage].
final class CycleTemplateRepositoryImpl
    with RepositoryGuard
    implements CycleTemplateRepository {
  /// Membuat [CycleTemplateRepositoryImpl] di atas [_storage].
  const CycleTemplateRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<CycleTemplateModel> get _store =>
      StoredValue<CycleTemplateModel>.json(
        key: _templateKey,
        fromJson: CycleTemplateModel.fromJson,
        toJson: (m) => m.toJson(),
        storage: _storage,
      );

  @override
  Future<Either<Failure, CycleTemplate>> getTemplate() => guard(() async {
    final model = await _store.read();
    return model?.toEntity() ?? .empty();
  });

  @override
  Future<Either<Failure, Unit>> saveTemplate(CycleTemplate template) =>
      guardVoid(() async {
        await _store.write(CycleTemplateModel.fromEntity(template));
      });
}
