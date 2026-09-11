part of 'investment_bloc.dart';

/// Event [InvestmentBloc].
sealed class InvestmentEvent {
  /// Membuat [InvestmentEvent].
  const InvestmentEvent();
}

/// Memuat pos tujuan, saldo, pinjaman, dan rencana investasi siklus
/// berjalan.
final class InvestmentOpened extends InvestmentEvent {
  /// Membuat [InvestmentOpened].
  const InvestmentOpened();
}

/// Memilih siklus ber-`id` [cycleId] untuk dilihat/disunting rencana
/// investasinya.
final class InvestmentCycleSelected extends InvestmentEvent {
  /// Membuat [InvestmentCycleSelected].
  const InvestmentCycleSelected(this.cycleId);

  /// Identitas siklus, format `YYYY-MM`.
  final String cycleId;
}

/// Menambah atau menyunting sebuah pos tujuan (FR-INV-001).
final class GoalSaved extends InvestmentEvent {
  /// Membuat [GoalSaved].
  const GoalSaved(this.goal);

  /// Pos yang disimpan.
  final Goal goal;
}

/// Menghapus pos ber-`id` [id].
final class GoalDeleted extends InvestmentEvent {
  /// Membuat [GoalDeleted].
  const GoalDeleted(this.id);

  /// Identitas pos.
  final String id;
}

/// Menyimpan rencana investasi siklus yang sedang dipilih (FR-INV-002,
/// FR-INV-003).
final class AllocationPlanSaved extends InvestmentEvent {
  /// Membuat [AllocationPlanSaved].
  const AllocationPlanSaved({required this.returnDeposit, required this.allocations});

  /// Tambahan dana dalam sen.
  final int returnDeposit;

  /// Persentase alokasi per pos.
  final List<AllocationPercentage> allocations;
}

/// Menambah atau menyunting sebuah pinjaman antar pos (FR-INV-004).
final class GoalLoanSaved extends InvestmentEvent {
  /// Membuat [GoalLoanSaved].
  const GoalLoanSaved(this.loan);

  /// Pinjaman yang disimpan.
  final GoalLoan loan;
}

/// Menghapus pinjaman ber-`id` [id].
final class GoalLoanDeleted extends InvestmentEvent {
  /// Membuat [GoalLoanDeleted].
  const GoalLoanDeleted(this.id);

  /// Identitas pinjaman.
  final String id;
}
