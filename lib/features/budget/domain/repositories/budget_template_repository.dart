import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';

/// Kontrak akses data [BudgetTemplate]. Lihat ADR-0005 — selalu
/// `Either<Failure, T>`, tidak pernah `throw Failure`.
abstract interface class BudgetTemplateRepository {
  /// Seluruh template, termasuk yang nonaktif.
  Future<Either<Failure, List<BudgetTemplate>>> listTemplates();

  /// Menyimpan [template] — menambah kalau `id` baru, menimpa kalau sudah
  /// ada.
  Future<Either<Failure, Unit>> saveTemplate(BudgetTemplate template);

  /// Menghapus template ber-`id` [id]. Tidak berefek kalau `id` tidak
  /// ditemukan.
  ///
  /// ⚠ Anggaran yang pernah dibuat dari template ini tidak ikut terhapus —
  /// ia salinan mandiri, tidak menyimpan rujukan ke templatenya.
  Future<Either<Failure, Unit>> deleteTemplate(String id);
}
