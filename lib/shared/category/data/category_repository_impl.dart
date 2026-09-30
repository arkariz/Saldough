import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/category/active_categories.dart';
import 'package:saldough/shared/category/data/category_model.dart';
import 'package:saldough/shared/category/domain/category.dart';
import 'package:saldough/shared/category/domain/category_repository.dart';

const _categoriesKey = StorageKey(namespace: 'category', name: 'all');
const _migrationKey = StorageKey(namespace: 'category', name: '_migration');

/// Implementasi [CategoryRepository] di atas [KeyValueStorage]: seluruh
/// kategori satu dokumen `category/all`, pola yang sama dengan dompet
/// (jumlahnya puluhan, bukan ribuan — ADR-026 §3.4).
///
/// Setiap baca dan tulis yang berhasil ikut memperbarui [ActiveCategories],
/// satu-satunya jalur tulis kategori, jadi cache tampilan tidak bisa basi.
final class CategoryRepositoryImpl with RepositoryGuard implements CategoryRepository {
  /// Membuat [CategoryRepositoryImpl] di atas [_storage].
  const CategoryRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<CategoryModel>> get _store => StoredValue<List<CategoryModel>>.json(
    key: _categoriesKey,
    fromJson: (json) =>
        (json['items'] as List<dynamic>).map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList(),
    toJson: (models) => {
      'schemaVersion': CategoryModel.schemaVersion,
      'items': models.map((m) => m.toJson()).toList(),
    },
    storage: _storage,
  );

  StoredValue<Map<String, dynamic>> get _migrationStore => StoredValue<Map<String, dynamic>>.json(
    key: _migrationKey,
    fromJson: (json) => json,
    toJson: (value) => value,
    storage: _storage,
  );

  List<Category> _publish(List<CategoryModel> models) {
    final categories = models.map((m) => m.toEntity()).toList();
    ActiveCategories.notifier.value = categories;
    return categories;
  }

  @override
  Future<Either<Failure, List<Category>>> listCategories() => guard(() async {
    return _publish(await _store.read() ?? const []);
  });

  @override
  Future<Either<Failure, Unit>> saveCategory(Category category) => saveCategories([category]);

  @override
  Future<Either<Failure, Unit>> saveCategories(List<Category> categories) => guardVoid(() async {
    // Kategori yang sudah ada ditimpa di tempatnya; yang baru ditambahkan
    // di akhir.
    final incoming = {for (final c in categories) c.id: CategoryModel.fromEntity(c)};
    final models = await _store.read() ?? <CategoryModel>[];
    final next = [
      for (final m in models) incoming.remove(m.id) ?? m,
      ...incoming.values,
    ];
    await _store.write(next);
    _publish(next);
  });

  @override
  Future<Either<Failure, bool>> isLegacyMigrationDone() => guard(() async {
    final marker = await _migrationStore.read();
    return marker?['version'] == 1;
  });

  @override
  Future<Either<Failure, Unit>> markLegacyMigrationDone() => guardVoid(() async {
    await _migrationStore.write({'version': 1});
  });
}
