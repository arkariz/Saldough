import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/savings_goal/domain/savings_goal.dart';

/// Penyimpanan tujuan tabungan (ADR-048 §3.4). Aturan bisnis ada di use case,
/// bukan di sini.
abstract interface class SavingsGoalRepository {
  /// Semua tujuan, urut dibuat.
  Future<Either<Failure, List<SavingsGoal>>> listGoals();

  /// Menyimpan [goal] baru atau menimpa yang ber-`id` sama di posisinya.
  Future<Either<Failure, Unit>> saveGoal(SavingsGoal goal);

  /// Menimpa beberapa tujuan sekaligus dalam satu tulis.
  Future<Either<Failure, Unit>> saveGoals(List<SavingsGoal> goals);

  /// Menghapus tujuan ber-`id` [id]. Tidak berefek bila tidak ada.
  Future<Either<Failure, Unit>> deleteGoal(String id);
}
