part of 'savings_goal_bloc.dart';

/// Peristiwa [SavingsGoalBloc].
sealed class SavingsGoalEvent {
  const SavingsGoalEvent();
}

/// Memuat (atau memuat ulang) tujuan, dompet, dan transaksi.
final class SavingsGoalStarted extends SavingsGoalEvent {
  /// Membuat [SavingsGoalStarted].
  const SavingsGoalStarted();
}

/// Menyimpan [goal] baru (beserta dompetnya, saldo awal [initialAmount]) atau
/// yang diubah. [activeLimit] `null` = Plus.
final class SavingsGoalSaved extends SavingsGoalEvent {
  /// Membuat [SavingsGoalSaved].
  const SavingsGoalSaved(this.goal, {this.activeLimit, this.initialAmount = 0});

  /// "Sudah terkumpul" untuk tujuan baru, dalam sen.
  final int initialAmount;

  /// Tujuan yang disimpan.
  final SavingsGoal goal;

  /// Batas tujuan Active Gratis, atau `null`.
  final int? activeLimit;
}

/// Mengarsipkan tujuan.
final class SavingsGoalArchived extends SavingsGoalEvent {
  /// Membuat [SavingsGoalArchived].
  const SavingsGoalArchived(this.goalId);

  /// Tujuan yang diarsipkan.
  final String goalId;
}

/// Mengaktifkan lagi tujuan. [activeLimit] `null` = Plus.
final class SavingsGoalReactivated extends SavingsGoalEvent {
  /// Membuat [SavingsGoalReactivated].
  const SavingsGoalReactivated(this.goalId, {this.activeLimit});

  /// Tujuan yang diaktifkan lagi.
  final String goalId;

  /// Batas tujuan Active Gratis, atau `null`.
  final int? activeLimit;
}

/// Menghapus tujuan; saldo dompet tidak berubah.
final class SavingsGoalDeleted extends SavingsGoalEvent {
  /// Membuat [SavingsGoalDeleted].
  const SavingsGoalDeleted(this.goalId);

  /// Tujuan yang dihapus.
  final String goalId;
}
