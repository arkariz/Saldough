import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';

/// Kontrak akses data [Budget]. Lihat ADR-0005 — selalu `Either<Failure, T>`,
/// tidak pernah `throw Failure`.
abstract interface class BudgetRepository {
  /// Seluruh anggaran, termasuk yang diarsipkan.
  Future<Either<Failure, List<Budget>>> listBudgets();

  /// Menyimpan [budget] — menambah kalau `id` baru, menimpa kalau sudah ada.
  Future<Either<Failure, Unit>> saveBudget(Budget budget);

  /// Menghapus anggaran ber-`id` [id]. Tidak berefek kalau `id` tidak
  /// ditemukan.
  ///
  /// ⚠ Transaksi yang tertaut ke pos anggaran ini tidak ikut dihapus, dan
  /// saldo dompet tidak berubah — `budgetItemId`-nya hanya jadi tidak
  /// menunjuk ke mana pun.
  Future<Either<Failure, Unit>> deleteBudget(String id);
}
