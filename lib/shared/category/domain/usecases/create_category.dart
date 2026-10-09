import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/category/domain/category.dart';
import 'package:saldough/shared/category/domain/category_repository.dart';

/// Membuat kategori buatan pengguna berjenis [CategoryKind] (ADR-026 §3.6).
///
/// Kalau sudah ada kategori sejenis bernama sama (beda huruf besar/spasi
/// dihitung sama), kategori itu yang dikembalikan — dipulihkan dulu kalau
/// terarsip — supaya "Tambah kategori" tidak pernah menghasilkan kembaran.
final class CreateCategory {
  /// Membuat [CreateCategory].
  const CreateCategory({required this._repository, this._clock});

  final CategoryRepository _repository;
  final DateTime Function()? _clock;

  /// Membuat (atau memakai ulang) kategori [name] berjenis [kind]. [name]
  /// wajib berisi selain spasi — ditegakkan formulir sebelum memanggil ini.
  /// [iconKey] ikon pilihan pengguna; `null` = ditebak dari nama (ADR-026).
  Future<Either<Failure, Category>> call(CategoryKind kind, String name, {String? iconKey}) async {
    assert(name.trim().isNotEmpty, 'Nama kategori tidak boleh kosong.');
    final List<Category> categories;
    switch (await _repository.listCategories()) {
      case Left(value: final failure):
        return left(failure);
      case Right(value: final listed):
        categories = listed;
    }

    final needle = normalizeCategoryText(name);
    for (final category in categories) {
      if (category.kind == kind && normalizeCategoryText(category.name) == needle) {
        if (!category.isArchived) return right(category);
        final restored = category.copyWith(isArchived: false, iconKey: iconKey);
        return (await _repository.saveCategory(restored)).map((_) => restored);
      }
    }

    final lastOrder = categories.fold<int>(-1, (max, c) => c.sortOrder > max ? c.sortOrder : max);
    final created = Category(
      id: 'user.${(_clock ?? DateTime.now)().microsecondsSinceEpoch}',
      kind: kind,
      name: name.trim(),
      iconKey: iconKey,
      sortOrder: lastOrder + 1,
    );
    return (await _repository.saveCategory(created)).map((_) => created);
  }
}
