import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/category/domain/built_in_categories.dart';
import 'package:saldough/shared/category/domain/category.dart';
import 'package:saldough/shared/category/domain/category_repository.dart';

/// Menambahkan kategori bawaan yang belum tersimpan, untuk pengguna yang
/// sudah lewat migrasi ADR-026 sebelum kategori itu ada (mis. Investasi,
/// ADR-049 §3.8). Kategori yang sudah ada (termasuk yang diarsipkan) tidak
/// disentuh; urutannya ditaruh di belakang kategori jenis yang sama.
final class AddMissingBuiltInCategories {
  /// Membuat [AddMissingBuiltInCategories].
  const AddMissingBuiltInCategories({required this._categoryRepository});

  final CategoryRepository _categoryRepository;

  /// Menjalankan penambahan. [builtInName] memberi nama tampilan dari kunci.
  Future<Either<Failure, Unit>> call({required String Function(String builtInKey) builtInName}) async {
    final List<Category> stored;
    switch (await _categoryRepository.listCategories()) {
      case Left(value: final failure):
        return left(failure);
      case Right(value: final list):
        stored = list;
    }
    // Belum dimigrasi: migrasi ADR-026 yang mengisi semua kategori bawaan.
    if (stored.isEmpty) return right(unit);
    final ids = {for (final c in stored) c.id};
    var nextOrder = stored.fold<int>(0, (max, c) => c.sortOrder > max ? c.sortOrder : max) + 1;
    final missing = [
      for (final builtIn in BuiltInCategories.all)
        if (!ids.contains(builtIn.id))
          Category(
            id: builtIn.id,
            kind: builtIn.kind,
            name: builtInName(builtIn.key),
            builtInKey: builtIn.key,
            iconKey: builtIn.iconKey,
            sortOrder: nextOrder++,
          ),
    ];
    if (missing.isEmpty) return right(unit);
    return _categoryRepository.saveCategories(missing);
  }
}
