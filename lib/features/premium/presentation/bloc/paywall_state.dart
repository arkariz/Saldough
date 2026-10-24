import 'package:saldough/features/premium/domain/purchase_models.dart';
import 'package:state_management/state_management.dart';

/// Tahap layar paywall (PlanCard dan tombolnya mengikuti tahap ini).
enum PaywallPhase {
  /// Harga sedang dimuat.
  loading,

  /// Paket siap dipilih.
  ready,

  /// Plus dijual tetapi harga tidak terjangkau (luring atau toko gagal).
  offline,

  /// Plus belum dijual: paywall hanya mengajak masuk akun (ADR-041 §3.13).
  notSelling,

  /// Pembayaran sedang diproses.
  buying,

  /// Play menunggu persetujuan pembayaran.
  pending,

  /// Pembayaran belum berhasil.
  failed,

  /// Plus sudah aktif.
  done,
}

/// Keadaan paywall.
final class PaywallState extends UiState<PaywallState> {
  /// Membuat [PaywallState].
  const PaywallState({
    this.phase = PaywallPhase.loading,
    this.plans = const [],
    this.selected,
    this.failure,
    this.deadline,
    super.effect,
  });

  /// Tahap layar.
  final PaywallPhase phase;

  /// Paket yang ditawarkan, tahunan lebih dulu.
  final List<PlanOption> plans;

  /// Paket terpilih.
  final PlusPlanKind? selected;

  /// Alasan gagal pada [PaywallPhase.failed].
  final PurchaseFailure? failure;

  /// Akhir penawaran khusus (Pendiri atau sesudah uji coba), bila ada.
  final DateTime? deadline;

  /// Pilihan terpilih, atau `null` bila belum ada paket.
  PlanOption? get selectedOption =>
      plans.where((p) => p.kind == selected).firstOrNull;

  /// Paket tidak boleh diubah selagi diproses atau menunggu persetujuan.
  bool get locked =>
      phase == PaywallPhase.buying || phase == PaywallPhase.pending;

  @override
  PaywallState copyWith({
    PaywallPhase? phase,
    List<PlanOption>? plans,
    PlusPlanKind? selected,
    PurchaseFailure? Function()? failure,
    DateTime? deadline,
    UiEffect? effect,
  }) => PaywallState(
    phase: phase ?? this.phase,
    plans: plans ?? this.plans,
    selected: selected ?? this.selected,
    failure: failure != null ? failure() : this.failure,
    deadline: deadline ?? this.deadline,
    effect: effect,
  );

  @override
  List<Object?> get props => [phase, plans, selected, failure, deadline];
}
