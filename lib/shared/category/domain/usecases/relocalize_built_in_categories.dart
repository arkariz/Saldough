import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/category/domain/category.dart';
import 'package:saldough/shared/category/domain/category_repository.dart';

/// Mengganti nama kategori bawaan ke bahasa baru saat bahasa aplikasi
/// berganti (ADR-028 §3.7). Hanya kategori yang namanya masih sama persis
/// dengan nama bawaan bahasa lama -- nama yang sudah diganti pengguna adalah
/// data miliknya dan tidak disentuh.
final class RelocalizeBuiltInCategories {
  /// Membuat [RelocalizeBuiltInCategories].
  const RelocalizeBuiltInCategories({required this._repository});

  final CategoryRepository _repository;

  /// [oldName] dan [newName] memberi nama bawaan per kunci dalam bahasa lama
  /// dan baru.
  Future<Either<Failure, Unit>> call({
    required String? Function(String builtInKey) oldName,
    required String? Function(String builtInKey) newName,
  }) async {
    final List<Category> categories;
    switch (await _repository.listCategories()) {
      case Left(value: final failure):
        return left(failure);
      case Right(value: final listed):
        categories = listed;
    }
    final renamed = <Category>[];
    for (final category in categories) {
      final key = category.builtInKey;
      if (key == null || oldName(key) != category.name) continue;
      final name = newName(key);
      if (name != null && name != category.name) renamed.add(category.copyWith(name: name));
    }
    if (renamed.isEmpty) return right(unit);
    return _repository.saveCategories(renamed);
  }
}
