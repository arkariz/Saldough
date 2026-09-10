import 'package:saldough/features/cycle/domain/entities/cycle_totals.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:state_management/state_management.dart';

/// State [CycleBloc]. `effect` tidak pernah masuk [props] (ADR-0003).
final class CycleState extends UiState<CycleState> {
  /// Membuat [CycleState].
  const CycleState({
    required this.cycle,
    required this.totals,
    required this.isLoading,
    this.unreviewedCount = 0,
    super.effect,
  });

  /// State awal sebelum siklus mana pun dimuat.
  factory CycleState.initial() => CycleState(
        cycle: MonthlyCycle.empty(''),
        totals: const CycleTotals(totalIncome: 0, totalBudget: 0, remainder: 0),
        isLoading: true,
      );

  /// Siklus yang sedang ditampilkan.
  final MonthlyCycle cycle;

  /// Total dan sisa, dihitung dari [cycle] lewat `CalculateCycleTotals`.
  final CycleTotals totals;

  /// Sedang memuat/menyimpan.
  final bool isLoading;

  /// Jumlah baris ber-`needsReview: true` — ditampilkan di ringkasan siklus
  /// (ADR-0008), supaya bulan tidak dianggap selesai selama masih menggantung.
  final int unreviewedCount;

  @override
  CycleState copyWith({
    MonthlyCycle? cycle,
    CycleTotals? totals,
    bool? isLoading,
    int? unreviewedCount,
    UiEffect? effect,
  }) {
    return CycleState(
      cycle: cycle ?? this.cycle,
      totals: totals ?? this.totals,
      isLoading: isLoading ?? this.isLoading,
      unreviewedCount: unreviewedCount ?? this.unreviewedCount,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [cycle, totals, isLoading, unreviewedCount];
}
