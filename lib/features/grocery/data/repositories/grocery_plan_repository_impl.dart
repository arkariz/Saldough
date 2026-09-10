import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/grocery/data/models/grocery_plan_model.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';
import 'package:saldough/features/grocery/domain/repositories/grocery_plan_repository.dart';

const _planKey = StorageKey(namespace: 'grocery', name: 'plan');

/// Implementasi [GroceryPlanRepository] di atas [KeyValueStorage], mengikuti
/// pola `CycleTemplateRepositoryImpl` (dokumen singleton).
final class GroceryPlanRepositoryImpl with RepositoryGuard implements GroceryPlanRepository {
  /// Membuat [GroceryPlanRepositoryImpl] di atas [_storage].
  const GroceryPlanRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<GroceryPlanModel> get _store => StoredValue<GroceryPlanModel>.json(
        key: _planKey,
        fromJson: GroceryPlanModel.fromJson,
        toJson: (m) => m.toJson(),
        storage: _storage,
      );

  @override
  Future<Either<Failure, GroceryPlan>> getPlan() => guard(() async {
        final model = await _store.read();
        return model?.toEntity() ?? .empty();
      });

  @override
  Future<Either<Failure, Unit>> savePlan(GroceryPlan plan) => guardVoid(() async {
        await _store.write(GroceryPlanModel.fromEntity(plan));
      });
}
