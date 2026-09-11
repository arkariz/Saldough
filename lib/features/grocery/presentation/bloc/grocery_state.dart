import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';
import 'package:saldough/features/grocery/domain/usecases/calculate_grocery_roll_up.dart';
import 'package:state_management/state_management.dart';

/// State [GroceryBloc]. `effect` tidak pernah masuk [props] (ADR-0003).
final class GroceryState extends UiState<GroceryState> {
  /// Membuat [GroceryState].
  const GroceryState({required this.plan, required this.isLoading, super.effect});

  /// State awal sebelum rencana belanja dimuat.
  factory GroceryState.initial() => GroceryState(plan: .empty(), isLoading: true);

  /// Rencana belanja yang sedang ditampilkan.
  final GroceryPlan plan;

  /// Sedang memuat/menyimpan.
  final bool isLoading;

  /// Roll-up bulanan — getter, dihitung ulang dari [plan] tiap diakses
  /// (pola sama seperti `CycleState.totals`), bukan field tersimpan.
  int get rollUpAmount => CalculateGroceryRollUp()(plan);

  @override
  GroceryState copyWith({GroceryPlan? plan, bool? isLoading, UiEffect? effect}) {
    return GroceryState(plan: plan ?? this.plan, isLoading: isLoading ?? this.isLoading, effect: effect);
  }

  @override
  List<Object?> get props => [plan, isLoading];
}
