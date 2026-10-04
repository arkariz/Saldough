import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/plan/domain/month_review.dart';

const _key = StorageKey(namespace: 'plan', name: 'month_review');
const _snapshotsKey = StorageKey(namespace: 'plan', name: 'forecast_snapshots');

/// [MonthReviewRepository] satu dokumen `{schemaVersion, monthStart,
/// doneSteps, completed, dismissed}` di `plan/month_review` dan
/// `{schemaVersion, items: [{monthStart, endBalance}]}` di
/// `plan/forecast_snapshots`.
final class MonthReviewRepositoryImpl with RepositoryGuard implements MonthReviewRepository {
  /// Membuat [MonthReviewRepositoryImpl].
  const MonthReviewRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<MonthReview> get _store => StoredValue<MonthReview>.json(
    key: _key,
    fromJson: (json) => MonthReview(
      monthStart: DateTime.parse(json['monthStart'] as String),
      doneSteps: {
        for (final name in (json['doneSteps'] as List<dynamic>? ?? const []).cast<String>())
          ?MonthReviewStep.values.asNameMap()[name],
      },
      completed: json['completed'] as bool? ?? false,
      dismissed: json['dismissed'] as bool? ?? false,
    ),
    toJson: (review) => {
      'schemaVersion': 1,
      'monthStart': review.monthStart.toIso8601String(),
      'doneSteps': [for (final step in review.doneSteps) step.name],
      'completed': review.completed,
      'dismissed': review.dismissed,
    },
    storage: _storage,
  );

  StoredValue<List<ForecastSnapshot>> get _snapshots => StoredValue<List<ForecastSnapshot>>.json(
    key: _snapshotsKey,
    fromJson: (json) => [
      for (final item in (json['items'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
        ForecastSnapshot(
          monthStart: DateTime.parse(item['monthStart'] as String),
          endBalance: item['endBalance'] as int,
        ),
    ],
    toJson: (snapshots) => {
      'schemaVersion': 1,
      'items': [
        for (final s in snapshots) {'monthStart': s.monthStart.toIso8601String(), 'endBalance': s.endBalance},
      ],
    },
    storage: _storage,
  );

  @override
  Future<Either<Failure, List<ForecastSnapshot>>> loadSnapshots() =>
      guard(() async => await _snapshots.read() ?? const <ForecastSnapshot>[]);

  @override
  Future<Either<Failure, Unit>> saveSnapshots(List<ForecastSnapshot> snapshots) =>
      guardVoid(() => _snapshots.write(snapshots));

  @override
  Future<Either<Failure, MonthReview?>> load() => guard(_store.read);

  @override
  Future<Either<Failure, Unit>> save(MonthReview review) => guardVoid(() => _store.write(review));
}
