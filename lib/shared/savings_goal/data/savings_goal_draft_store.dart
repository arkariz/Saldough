import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/savings_goal/data/savings_goal_model.dart';
import 'package:saldough/shared/savings_goal/domain/savings_goal.dart';

const _draftKey = StorageKey(namespace: 'savings_goal', name: 'draft');

/// Draf formulir tujuan baru yang tertahan paywall P11 (ADR-048 §3.5): satu
/// draf, milik perangkat, tidak ikut cadangan.
final class SavingsGoalDraftStore with RepositoryGuard {
  /// Membuat [SavingsGoalDraftStore].
  const SavingsGoalDraftStore({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<SavingsGoal> get _store => StoredValue<SavingsGoal>.json(
    key: _draftKey,
    fromJson: (json) => SavingsGoalModel.fromJson(json['draft'] as Map<String, dynamic>),
    toJson: (goal) => {'schemaVersion': SavingsGoalModel.schemaVersion, 'draft': SavingsGoalModel.toJson(goal)},
    storage: _storage,
  );

  /// Draf tersimpan, atau `null`.
  Future<Either<Failure, SavingsGoal?>> read() => guard(_store.read);

  /// Menyimpan [goal] sebagai draf, menimpa yang lama.
  Future<Either<Failure, Unit>> save(SavingsGoal goal) => guardVoid(() => _store.write(goal));

  /// Membuang draf.
  Future<Either<Failure, Unit>> clear() => guardVoid(_store.remove);
}
