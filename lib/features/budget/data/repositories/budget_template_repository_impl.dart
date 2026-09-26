import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/budget/data/models/budget_template_model.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/domain/repositories/budget_template_repository.dart';

const _templatesKey = StorageKey(namespace: 'budget_template', name: 'all');

/// Implementasi [BudgetTemplateRepository] di atas [KeyValueStorage],
/// mengikuti pola `BudgetRepositoryImpl`.
///
/// Seluruh template disimpan sebagai satu dokumen JSON di kunci
/// `budget_template/all` (ADR-012), terpisah dari `budget/all` supaya
/// anggaran dan templatenya tidak pernah tertulis dalam satu operasi.
final class BudgetTemplateRepositoryImpl with RepositoryGuard implements BudgetTemplateRepository {
  /// Membuat [BudgetTemplateRepositoryImpl] di atas [_storage].
  const BudgetTemplateRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<BudgetTemplateModel>> get _store => StoredValue<List<BudgetTemplateModel>>.json(
    key: _templatesKey,
    fromJson: (json) =>
        (json['items'] as List<dynamic>).map((e) => BudgetTemplateModel.fromJson(e as Map<String, dynamic>)).toList(),
    toJson: (models) => {
      'schemaVersion': BudgetTemplateModel.schemaVersion,
      'items': models.map((m) => m.toJson()).toList(),
    },
    storage: _storage,
  );

  @override
  Future<Either<Failure, List<BudgetTemplate>>> listTemplates() => guard(() async {
    final models = await _store.read();
    return (models ?? const []).map((m) => m.toEntity()).toList();
  });

  @override
  Future<Either<Failure, Unit>> saveTemplate(BudgetTemplate template) => guardVoid(() async {
    final models = await _store.read() ?? <BudgetTemplateModel>[];
    final index = models.indexWhere((m) => m.id == template.id);
    final model = BudgetTemplateModel.fromEntity(template);
    // Menimpa di posisi semula supaya urutan daftar tidak melompat.
    final next = [...models];
    if (index == -1) {
      next.add(model);
    } else {
      next[index] = model;
    }
    await _store.write(next);
  });

  @override
  Future<Either<Failure, Unit>> deleteTemplate(String id) => guardVoid(() async {
    final models = await _store.read() ?? <BudgetTemplateModel>[];
    await _store.write(models.where((m) => m.id != id).toList());
  });
}
