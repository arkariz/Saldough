import 'package:saldough/features/investment/domain/entities/cycle_investment_snapshot.dart';
import 'package:saldough/features/investment/domain/entities/goal_loan.dart';
import 'package:saldough/features/investment/domain/usecases/calculate_allocations.dart';
import 'package:saldough/shared/goal/goal.dart';
import 'package:state_management/state_management.dart';

/// Siklus berjalan saat ini, format `YYYY-MM` — bawaan `cycleId` layar
/// investasi sebelum pemilik memilih siklus lain. Sama seperti
/// `CycleRouteModule._currentCycleId`.
String currentCycleId() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

/// State [InvestmentBloc]. `effect` tidak pernah masuk [props] (ADR-0003).
final class InvestmentState extends UiState<InvestmentState> {
  /// Membuat [InvestmentState].
  const InvestmentState({
    required this.goals,
    required this.balances,
    required this.loans,
    required this.cycleId,
    required this.cycleSnapshot,
    required this.closedSnapshots,
    required this.isLoading,
    this.cycleIds = const [],
    super.effect,
  });

  /// State awal sebelum data dimuat, siklus bawaan bulan berjalan.
  factory InvestmentState.initial() => InvestmentState(
        goals: const [],
        balances: const {},
        loans: const [],
        cycleId: currentCycleId(),
        cycleSnapshot: null,
        closedSnapshots: const [],
        isLoading: true,
      );

  /// Seluruh pos tujuan terdaftar (FR-INV-001).
  final List<Goal> goals;

  /// Saldo tiap pos, `goalId` → saldo dalam sen (T-5.7/FR-INV-005).
  final Map<String, int> balances;

  /// Seluruh pinjaman antar pos terdaftar (FR-INV-004).
  final List<GoalLoan> loans;

  /// Siklus yang sedang dilihat/disunting rencana investasinya.
  final String cycleId;

  /// Potret rencana investasi [cycleId], atau `null` kalau belum dimuat atau
  /// siklusnya belum ada.
  final CycleInvestmentSnapshot? cycleSnapshot;

  /// Potret seluruh siklus TERTUTUP — dasar [allocationHistoryFor] (T-5.8).
  final List<CycleInvestmentSnapshot> closedSnapshots;

  /// Sedang memuat/menyimpan.
  final bool isLoading;

  /// Seluruh `id` siklus yang sudah dibuat, terurut menaik (UX-09: dasar
  /// pemilih siklus yang dilihat/disunting, bukan input `YYYY-MM` bebas).
  final List<String> cycleIds;

  /// Saldo pos ber-`id` [goalId], nol kalau belum terhitung.
  int balanceOf(String goalId) => balances[goalId] ?? 0;

  /// Total portofolio — jumlah saldo seluruh pos.
  int get totalPortfolio => balances.values.fold(0, (sum, b) => sum + b);

  /// Riwayat alokasi pos ber-`id` [goalId] dari [closedSnapshots] — satu
  /// entri `(cycleId, amount)` per siklus tertutup yang mengalokasikan ke
  /// pos ini (T-5.8/FR-INV-005).
  List<(String cycleId, int amount)> allocationHistoryFor(String goalId) {
    final calculate = CalculateAllocations();
    return [
      for (final snapshot in closedSnapshots)
        for (final entry
            in calculate(investmentBudget: snapshot.investmentBudget, allocations: snapshot.allocations))
          if (entry.goalId == goalId) (snapshot.cycleId, entry.amount),
    ];
  }

  @override
  InvestmentState copyWith({
    List<Goal>? goals,
    Map<String, int>? balances,
    List<GoalLoan>? loans,
    String? cycleId,
    List<CycleInvestmentSnapshot>? closedSnapshots,
    bool? isLoading,
    List<String>? cycleIds,
    UiEffect? effect,
  }) {
    return InvestmentState(
      goals: goals ?? this.goals,
      balances: balances ?? this.balances,
      loans: loans ?? this.loans,
      cycleId: cycleId ?? this.cycleId,
      cycleSnapshot: cycleSnapshot,
      closedSnapshots: closedSnapshots ?? this.closedSnapshots,
      isLoading: isLoading ?? this.isLoading,
      cycleIds: cycleIds ?? this.cycleIds,
      effect: effect,
    );
  }

  /// Helper transisi state — berpindah menampilkan [snapshot] milik
  /// [cycleId] yang sedang dipilih. Metode terpisah dari [copyWith] supaya
  /// `null` di sini bisa berarti "belum ada siklus ini", bukan "tidak
  /// diganti" (jebakan copyWith klasik untuk field nullable).
  InvestmentState withSnapshot(CycleInvestmentSnapshot? snapshot, {UiEffect? effect}) {
    return InvestmentState(
      goals: goals,
      balances: balances,
      loans: loans,
      cycleId: cycleId,
      cycleSnapshot: snapshot,
      closedSnapshots: closedSnapshots,
      isLoading: false,
      cycleIds: cycleIds,
      effect: effect,
    );
  }

  @override
  List<Object?> get props =>
      [goals, balances, loans, cycleId, cycleSnapshot, closedSnapshots, isLoading, cycleIds];
}
