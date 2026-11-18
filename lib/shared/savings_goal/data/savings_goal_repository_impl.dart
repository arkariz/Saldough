import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/savings_goal/data/savings_goal_model.dart';
import 'package:saldough/shared/savings_goal/domain/savings_goal.dart';
import 'package:saldough/shared/savings_goal/domain/savings_goal_repository.dart';

const _goalsKey = StorageKey(namespace: 'savings_goal', name: 'all');

/// [SavingsGoalRepository] di atas satu dokumen `savings_goal_all`
/// (ADR-048 §3.4), mengikuti `RecurringRuleRepositoryImpl`.
final class SavingsGoalRepositoryImpl with RepositoryGuard implements SavingsGoalRepository {
  /// Membuat [SavingsGoalRepositoryImpl].
  const SavingsGoalRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<SavingsGoal>> get _store => StoredValue<List<SavingsGoal>>.json(
    key: _goalsKey,
    fromJson: (json) =>
        (json['items'] as List<dynamic>).map((e) => SavingsGoalModel.fromJson(e as Map<String, dynamic>)).toList(),
    toJson: (goals) => {
      'schemaVersion': SavingsGoalModel.schemaVersion,
      'items': goals.map(SavingsGoalModel.toJson).toList(),
    },
    storage: _storage,
  );

  @override
  Future<Either<Failure, List<SavingsGoal>>> listGoals() => guard(() async => await _store.read() ?? const []);

  @override
  Future<Either<Failure, Unit>> saveGoal(SavingsGoal goal) => guardVoid(() async {
    final goals = await _store.read() ?? <SavingsGoal>[];
    final index = goals.indexWhere((g) => g.id == goal.id);
    final next = [...goals];
    if (index == -1) {
      next.add(goal);
    } else {
      next[index] = goal;
    }
    await _store.write(next);
  });

  @override
  Future<Either<Failure, Unit>> saveGoals(List<SavingsGoal> goals) => guardVoid(() => _store.write(goals));

  @override
  Future<Either<Failure, Unit>> deleteGoal(String id) => guardVoid(() async {
    final goals = await _store.read() ?? <SavingsGoal>[];
    await _store.write(goals.where((g) => g.id != id).toList());
  });
}
