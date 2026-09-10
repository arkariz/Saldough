import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/cycle/data/models/cycle_model.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:saldough/features/cycle/domain/repositories/roll_up_resolver.dart';

const _indexKey = StorageKey(namespace: 'cycle', name: '_index');

StorageKey _cycleKey(String id) => StorageKey(namespace: 'cycle', name: id);

/// Implementasi [CycleRepository] di atas [KeyValueStorage], mengikuti pola
/// `CycleRepositoryImpl` di ARCHITECTURE_OVERVIEW.md.
///
/// Setiap [getCycle] menghitung ulang baris `rollUp` lewat [_resolver] —
/// nilai di dokumen tersimpan tidak pernah dipercaya (ADR-0008).
final class CycleRepositoryImpl with RepositoryGuard implements CycleRepository {
  /// Membuat [CycleRepositoryImpl] di atas [_storage] dan [_resolver].
  const CycleRepositoryImpl({required this._storage, required this._resolver});

  final KeyValueStorage _storage;
  final RollUpResolver _resolver;

  StoredValue<CycleModel> _cycleStore(String id) => StoredValue<CycleModel>.json(
        key: _cycleKey(id),
        fromJson: CycleModel.fromJson,
        toJson: (m) => m.toJson(),
        storage: _storage,
      );

  StoredValue<List<String>> get _indexStore => StoredValue<List<String>>.json(
        key: _indexKey,
        fromJson: (json) => (json['ids'] as List<dynamic>).cast<String>(),
        toJson: (ids) => {'ids': ids},
        storage: _storage,
      );

  @override
  Future<Either<Failure, MonthlyCycle?>> getCycle(String id) => guard(() async {
        final model = await _cycleStore(id).read();
        if (model == null) return null;
        return _resolveRollUps(model.toEntity());
      });

  Future<MonthlyCycle> _resolveRollUps(MonthlyCycle cycle) async {
    final resolvedLines = await Future.wait(cycle.budgetLines.map((line) async {
      if (line.kind != .rollUp) return line;
      final resolution = await _resolver.resolve(line.rollUpSource!);
      return line.copyWith(
        amount: resolution.amount,
        rollUpSourceUnavailable: !resolution.isAvailable,
      );
    }));
    return cycle.copyWith(budgetLines: resolvedLines);
  }

  @override
  Future<Either<Failure, List<String>>> listCycleIds() => guard(() async {
        final ids = await _indexStore.read() ?? const [];
        return [...ids]..sort();
      });

  @override
  Future<Either<Failure, Unit>> saveCycle(MonthlyCycle cycle) => guardVoid(() async {
        await _cycleStore(cycle.id).write(CycleModel.fromEntity(cycle));
        final ids = await _indexStore.read() ?? const [];
        if (!ids.contains(cycle.id)) {
          await _indexStore.write([...ids, cycle.id]);
        }
      });
}
