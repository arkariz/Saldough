import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';
import 'package:saldough/features/grocery/domain/usecases/calculate_grocery_roll_up.dart';
import 'package:state_management/state_management.dart';

/// Siklus bulan berjalan saat ini, format `YYYY-MM` — bawaan `cycleId` layar
/// Rencana Belanja sebelum pemilik memilih bulan lain. Sama seperti
/// `CycleRouteModule._currentCycleId`/`investment_state.dart`'s
/// `currentCycleId()` — duplikasi kecil yang sudah jadi pola di proyek ini.
String currentCycleId() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

/// State [GroceryBloc]. `effect` tidak pernah masuk [props] (ADR-0003).
final class GroceryState extends UiState<GroceryState> {
  /// Membuat [GroceryState].
  const GroceryState({
    required this.plan,
    required this.cycleId,
    required this.isLoading,
    this.cycleIds = const [],
    super.effect,
  });

  /// State awal sebelum rencana belanja dimuat, bulan bawaan bulan berjalan.
  factory GroceryState.initial() {
    final id = currentCycleId();
    return GroceryState(plan: .empty(id), cycleId: id, isLoading: true);
  }

  /// Rencana belanja yang sedang ditampilkan — selalu ber-`id` [cycleId]
  /// (tautan 1:1 `GroceryPlan`↔`MonthlyCycle`, laporan pemilik).
  final GroceryPlan plan;

  /// Siklus (bulan) yang sedang dilihat/disunting rencana belanjanya.
  final String cycleId;

  /// Sedang memuat/menyimpan.
  final bool isLoading;

  /// Seluruh `id` siklus yang sudah dibuat, terurut menaik (UX-09: dasar
  /// pemilih bulan yang dilihat/disunting, bukan mengetik `YYYY-MM` dengan
  /// tangan) — pola sama seperti `InvestmentState.cycleIds`.
  final List<String> cycleIds;

  /// Roll-up bulanan — getter, dihitung ulang dari [plan] tiap diakses
  /// (pola sama seperti `CycleState.totals`), bukan field tersimpan.
  int get rollUpAmount => CalculateGroceryRollUp()(plan);

  @override
  GroceryState copyWith({
    GroceryPlan? plan,
    String? cycleId,
    bool? isLoading,
    List<String>? cycleIds,
    UiEffect? effect,
  }) {
    return GroceryState(
      plan: plan ?? this.plan,
      cycleId: cycleId ?? this.cycleId,
      isLoading: isLoading ?? this.isLoading,
      cycleIds: cycleIds ?? this.cycleIds,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [plan, cycleId, isLoading, cycleIds];
}
