import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_item.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';
import 'package:saldough/features/grocery/domain/repositories/grocery_plan_repository.dart';
import 'package:saldough/features/grocery/presentation/bloc/grocery_state.dart';
import 'package:state_management/state_management.dart';

part 'grocery_effect.dart';
part 'grocery_event.dart';

/// Bloc layar rencana belanja. Lihat ARCHITECTURE_OVERVIEW.md bagian
/// "Menulis satu fitur".
final class GroceryBloc extends Bloc<GroceryEvent, GroceryState> {
  /// Membuat [GroceryBloc].
  GroceryBloc({required this._repository}) : super(GroceryState.initial()) {
    on<GroceryPlanLoaded>(_onLoaded);
    on<GroceryItemSaved>(_onItemSaved);
    on<GroceryItemRemoved>(_onItemRemoved);
    on<WeeksPerMonthChanged>(_onWeeksPerMonthChanged);
  }

  final GroceryPlanRepository _repository;

  Future<void> _onLoaded(GroceryPlanLoaded event, Emitter<GroceryState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await _repository.getPlan();
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
      case Right(value: final plan):
        emit(state.copyWith(plan: plan, isLoading: false));
    }
  }

  Future<void> _onItemSaved(GroceryItemSaved event, Emitter<GroceryState> emit) async {
    final items = event.isWeekly ? state.plan.weeklyItems : state.plan.monthlyItems;
    final item = GroceryItem(
      id: event.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: event.name,
      quantity: event.quantity,
      unitPrice: event.unitPrice,
      amountOverride: event.amountOverride,
    );
    final nextItems = [...items.where((i) => i.id != item.id), item];
    final plan = event.isWeekly
        ? state.plan.copyWith(weeklyItems: nextItems)
        : state.plan.copyWith(monthlyItems: nextItems);
    await _saveAndEmit(emit, plan);
  }

  Future<void> _onItemRemoved(GroceryItemRemoved event, Emitter<GroceryState> emit) async {
    final items = event.isWeekly ? state.plan.weeklyItems : state.plan.monthlyItems;
    final nextItems = items.where((i) => i.id != event.id).toList();
    final plan = event.isWeekly
        ? state.plan.copyWith(weeklyItems: nextItems)
        : state.plan.copyWith(monthlyItems: nextItems);
    await _saveAndEmit(emit, plan);
  }

  Future<void> _onWeeksPerMonthChanged(WeeksPerMonthChanged event, Emitter<GroceryState> emit) async {
    await _saveAndEmit(emit, state.plan.copyWith(weeksPerMonth: event.weeksPerMonth));
  }

  Future<void> _saveAndEmit(Emitter<GroceryState> emit, GroceryPlan plan) async {
    final result = await _repository.savePlan(plan);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        emit(state.copyWith(plan: plan));
    }
  }
}
