import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/card/data/models/recurring_subscription_model.dart';
import 'package:saldough/features/card/domain/entities/recurring_subscription.dart';
import 'package:saldough/features/card/domain/repositories/recurring_subscription_repository.dart';

const _subscriptionsKey = StorageKey(namespace: 'card', name: 'subscriptions');

/// Implementasi [RecurringSubscriptionRepository] di atas [KeyValueStorage],
/// mengikuti pola `GoalRepositoryImpl` (ADR-0009).
final class RecurringSubscriptionRepositoryImpl
    with RepositoryGuard
    implements RecurringSubscriptionRepository {
  /// Membuat [RecurringSubscriptionRepositoryImpl] di atas [_storage].
  const RecurringSubscriptionRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<RecurringSubscriptionModel>> get _store =>
      StoredValue<List<RecurringSubscriptionModel>>.json(
        key: _subscriptionsKey,
        fromJson: (json) => (json['items'] as List<dynamic>)
            .map((e) => RecurringSubscriptionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        toJson: (models) => {
          'schemaVersion': RecurringSubscriptionModel.schemaVersion,
          'items': models.map((m) => m.toJson()).toList(),
        },
        storage: _storage,
      );

  @override
  Future<Either<Failure, List<RecurringSubscription>>> listSubscriptions() => guard(() async {
        final models = await _store.read();
        return (models ?? const []).map((m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, Unit>> saveSubscription(RecurringSubscription subscription) => guardVoid(() async {
        final models = await _store.read() ?? <RecurringSubscriptionModel>[];
        final next = [
          ...models.where((m) => m.id != subscription.id),
          RecurringSubscriptionModel.fromEntity(subscription),
        ];
        await _store.write(next);
      });

  @override
  Future<Either<Failure, Unit>> deleteSubscription(String id) => guardVoid(() async {
        final models = await _store.read() ?? <RecurringSubscriptionModel>[];
        await _store.write(models.where((m) => m.id != id).toList());
      });
}
