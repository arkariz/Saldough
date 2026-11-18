import 'package:navigation/navigation.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';

// Satu-satunya berkas fitur `savings_goal` yang boleh diimpor fitur lain
// (ADR-030 §3.3).

/// Masukan rute rincian tujuan.
final class SavingsGoalDetailInput extends RouteInput {
  /// Membuat [SavingsGoalDetailInput].
  const SavingsGoalDetailInput(this.goalId);

  /// Tujuan yang dibuka.
  final String goalId;
}

/// Masukan rute formulir tujuan: [goal] `null` = tujuan baru.
final class SavingsGoalFormInput extends RouteInput {
  /// Membuat [SavingsGoalFormInput].
  const SavingsGoalFormInput({this.goal});

  /// Tujuan yang diubah, atau `null`.
  final SavingsGoal? goal;
}

/// Kunci rute fitur tujuan tabungan (ADR-048 §3.8).
abstract final class SavingsGoalRouteKeys {
  /// Rincian tujuan.
  static const detail = RouteKey<SavingsGoalDetailInput>('savingsGoal.detail');

  /// Formulir buat/ubah tujuan.
  static const form = RouteKey<SavingsGoalFormInput>('savingsGoal.form');
}
