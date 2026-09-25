import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/budget/data/models/budget_model.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';

const _budgetsKey = StorageKey(namespace: 'budget', name: 'all');

/// Implementasi [BudgetRepository] di atas [KeyValueStorage], mengikuti pola
/// `WalletRepositoryImpl`.
///
/// Seluruh anggaran beserta posnya disimpan sebagai satu dokumen JSON di
/// kunci `budget/all` (ADR-012) — jumlahnya kecil, tidak perlu dipartisi.
final class BudgetRepositoryImpl with RepositoryGuard implements BudgetRepository {
  /// Membuat [BudgetRepositoryImpl] di atas [_storage].
  const BudgetRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<BudgetModel>> get _store => StoredValue<List<BudgetModel>>.json(
    key: _budgetsKey,
    fromJson: (json) =>
        (json['items'] as List<dynamic>).map((e) => BudgetModel.fromJson(e as Map<String, dynamic>)).toList(),
    toJson: (models) => {
      'schemaVersion': BudgetModel.schemaVersion,
      'items': models.map((m) => m.toJson()).toList(),
    },
    storage: _storage,
  );

  @override
  Future<Either<Failure, List<Budget>>> listBudgets() => guard(() async {
    final models = await _store.read();
    return (models ?? const []).map((m) => m.toEntity()).toList();
  });

  @override
  Future<Either<Failure, Unit>> saveBudget(Budget budget) => guardVoid(() async {
    final models = await _store.read() ?? <BudgetModel>[];
    final index = models.indexWhere((m) => m.id == budget.id);
    final model = BudgetModel.fromEntity(budget);
    // Menimpa di posisi semula supaya urutan daftar tidak melompat
    // setiap kali sebuah anggaran disunting.
    final next = [...models];
    if (index == -1) {
      next.add(model);
    } else {
      next[index] = model;
    }
    await _store.write(next);
  });

  @override
  Future<Either<Failure, Unit>> deleteBudget(String id) => guardVoid(() async {
    final models = await _store.read() ?? <BudgetModel>[];
    await _store.write(models.where((m) => m.id != id).toList());
  });
}
