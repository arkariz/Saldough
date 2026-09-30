import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/category/domain/category.dart';

/// Kontrak akses data [Category]. Lihat ADR-0005 — selalu `Either<Failure, T>`.
abstract interface class CategoryRepository {
  /// Seluruh kategori, aktif maupun terarsip.
  Future<Either<Failure, List<Category>>> listCategories();

  /// Menyimpan [category] — menambah kalau `id` baru, menimpa kalau sudah ada.
  Future<Either<Failure, Unit>> saveCategory(Category category);

  /// Menyimpan banyak kategori sekaligus dalam satu tulis (dipakai migrasi).
  /// Kategori tersimpan yang tidak ada di [categories] tetap ada.
  Future<Either<Failure, Unit>> saveCategories(List<Category> categories);

  /// Apakah migrasi label lama (ADR-026 §3.4) sudah selesai di perangkat ini.
  Future<Either<Failure, bool>> isLegacyMigrationDone();

  /// Menandai migrasi label lama selesai.
  Future<Either<Failure, Unit>> markLegacyMigrationDone();
}
