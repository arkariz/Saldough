import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/goal/domain/goal.dart';

/// Kontrak akses data [Goal]. Lihat ADR-0005 — selalu `Either<Failure, T>`,
/// tidak pernah `throw Failure`.
abstract interface class GoalRepository {
  /// Daftar seluruh pos tujuan terdaftar.
  Future<Either<Failure, List<Goal>>> listGoals();

  /// Menyimpan [goal] — menambah kalau `id` baru, menimpa kalau sudah ada.
  Future<Either<Failure, Unit>> saveGoal(Goal goal);

  /// Menghapus pos ber-`id` [id]. Tidak berefek kalau `id` tidak ditemukan.
  Future<Either<Failure, Unit>> deleteGoal(String id);
}
