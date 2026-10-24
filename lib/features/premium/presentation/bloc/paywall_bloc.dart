import 'package:saldough/features/premium/domain/plus_purchasing.dart';
import 'package:saldough/features/premium/domain/purchase_models.dart';
import 'package:saldough/features/premium/presentation/bloc/paywall_state.dart';
import 'package:state_management/state_management.dart';

part 'paywall_event.dart';

/// Bloc layar paywall (ADR-041 §3.5): memuat harga dari toko, memilih paket,
/// dan membeli. Tidak pernah mengubah data keuangan; hasil beli dibaca layar
/// lewat hak (`ActivePlan`).
final class PaywallBloc extends Bloc<PaywallEvent, PaywallState> {
  /// Membuat [PaywallBloc].
  PaywallBloc({required this._purchasing}) : super(const PaywallState()) {
    on<PaywallStarted>(_onStarted);
    on<PaywallPlanSelected>(_onPlanSelected);
    on<PaywallBuyRequested>(_onBuyRequested);
  }

  final PlusPurchasing _purchasing;

  Future<void> _onStarted(
    PaywallStarted event,
    Emitter<PaywallState> emit,
  ) async {
    if (!_purchasing.isSelling) {
      emit(const PaywallState(phase: PaywallPhase.notSelling));
      return;
    }
    emit(PaywallState(selected: state.selected));
    final offered = await _purchasing.offered();
    if (offered.isEmpty) {
      emit(const PaywallState(phase: PaywallPhase.offline));
      return;
    }
    // Tahunan lebih dulu (bawaan terpilih), bulanan sesudahnya.
    final plans = [
      ...offered.options.where((o) => o.kind != PlusPlanKind.monthly),
      ...offered.options.where((o) => o.kind == PlusPlanKind.monthly),
    ];
    emit(
      PaywallState(
        phase: PaywallPhase.ready,
        plans: plans,
        selected: plans.first.kind,
        deadline: offered.deadline,
      ),
    );
  }

  void _onPlanSelected(PaywallPlanSelected event, Emitter<PaywallState> emit) {
    if (state.locked || !state.plans.any((p) => p.kind == event.kind)) return;
    emit(state.copyWith(selected: event.kind));
  }

  Future<void> _onBuyRequested(
    PaywallBuyRequested event,
    Emitter<PaywallState> emit,
  ) async {
    final option = state.selectedOption;
    if (option == null || state.locked) return;
    emit(state.copyWith(phase: PaywallPhase.buying, failure: () => null));
    final result = await _purchasing.buy(option);
    emit(switch (result) {
      BuyDone() => state.copyWith(phase: PaywallPhase.done),
      BuyCancelled() => state.copyWith(phase: PaywallPhase.ready),
      BuyPending() => state.copyWith(phase: PaywallPhase.pending),
      BuyFailed(:final reason) => state.copyWith(
        phase: PaywallPhase.failed,
        failure: () => reason,
      ),
    });
  }
}
