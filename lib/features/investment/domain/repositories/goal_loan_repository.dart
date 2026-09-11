import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/investment/domain/entities/goal_loan.dart';

/// Kontrak akses data [GoalLoan]. Lihat ADR-0005 — selalu
/// `Either<Failure, T>`, tidak pernah `throw Failure`.
abstract interface class GoalLoanRepository {
  /// Seluruh pinjaman terdaftar, lintas pos.
  Future<Either<Failure, List<GoalLoan>>> listLoans();

  /// Menyimpan [loan] — menambah kalau `id` baru, menimpa kalau sudah ada.
  Future<Either<Failure, Unit>> saveLoan(GoalLoan loan);

  /// Menghapus pinjaman ber-`id` [id]. Tidak berefek kalau `id` tidak
  /// ditemukan.
  Future<Either<Failure, Unit>> deleteLoan(String id);
}
