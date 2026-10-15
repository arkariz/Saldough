import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/transaction/domain/history_segment.dart';

const _key = StorageKey(namespace: 'settings', name: 'history_segment');

/// [HistorySegmentRepository] di atas [KeyValueStorage]: satu dokumen
/// `{schemaVersion, segment}` di `settings/history_segment`; nilai yang tidak
/// dikenal dibaca sebagai [HistorySegment.list].
final class HistorySegmentRepositoryImpl with RepositoryGuard implements HistorySegmentRepository {
  /// Membuat [HistorySegmentRepositoryImpl].
  const HistorySegmentRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<HistorySegment> get _store => StoredValue<HistorySegment>.json(
    key: _key,
    fromJson: (json) => json['segment'] == HistorySegment.analysis.name ? HistorySegment.analysis : HistorySegment.list,
    toJson: (segment) => {'schemaVersion': 1, 'segment': segment.name},
    storage: _storage,
  );

  @override
  Future<Either<Failure, HistorySegment>> load() => guard(() async => await _store.read() ?? HistorySegment.list);

  @override
  Future<Either<Failure, Unit>> save(HistorySegment segment) => guardVoid(() => _store.write(segment));
}
