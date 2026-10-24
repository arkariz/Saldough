part of 'paywall_bloc.dart';

/// Event [PaywallBloc].
sealed class PaywallEvent {
  /// Membuat [PaywallEvent].
  const PaywallEvent();
}

/// Layar dibuka atau "Coba lagi" diketuk: muat harga.
final class PaywallStarted extends PaywallEvent {
  /// Membuat [PaywallStarted].
  const PaywallStarted();
}

/// Paket dipilih.
final class PaywallPlanSelected extends PaywallEvent {
  /// Membuat [PaywallPlanSelected].
  const PaywallPlanSelected(this.kind);

  /// Paket yang dipilih.
  final PlusPlanKind kind;
}

/// Tombol beli diketuk.
final class PaywallBuyRequested extends PaywallEvent {
  /// Membuat [PaywallBuyRequested].
  const PaywallBuyRequested();
}
