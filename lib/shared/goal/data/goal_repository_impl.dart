import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/goal/data/goal_model.dart';
import 'package:saldough/shared/goal/domain/goal.dart';
import 'package:saldough/shared/goal/domain/goal_repository.dart';

const _goalsKey = StorageKey(namespace: 'goal', name: 'all');

/// Implementasi [GoalRepository] di atas [KeyValueStorage], mengikuti pola
/// `CycleRepositoryImpl` di ARCHITECTURE_OVERVIEW.md.
///
/// Seluruh pos disimpan sebagai satu dokumen JSON (daftar kecil, lihat
/// `models` package note di ARCHITECTURE_OVERVIEW.md soal volume data MVP).
final class GoalRepositoryImpl with RepositoryGuard implements GoalRepository {
  /// Membuat [GoalRepositoryImpl] di atas [_storage].
  const GoalRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<GoalModel>> get _store => StoredValue<List<GoalModel>>.json(
        key: _goalsKey,
        fromJson: (json) => (json['items'] as List<dynamic>)
            .map((e) => GoalModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        toJson: (models) => {
          'schemaVersion': GoalModel.schemaVersion,
          'items': models.map((m) => m.toJson()).toList(),
        },
        storage: _storage,
      );

  @override
  Future<Either<Failure, List<Goal>>> listGoals() => guard(() async {
        final models = await _store.read();
        return (models ?? const []).map((m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, Unit>> saveGoal(Goal goal) => guardVoid(() async {
        final models = await _store.read() ?? <GoalModel>[];
        final next = [
          ...models.where((m) => m.id != goal.id),
          GoalModel.fromEntity(goal),
        ];
        await _store.write(next);
      });

  @override
  Future<Either<Failure, Unit>> deleteGoal(String id) => guardVoid(() async {
        final models = await _store.read() ?? <GoalModel>[];
        await _store.write(models.where((m) => m.id != id).toList());
      });
}
