import 'package:navigation/navigation.dart';
import 'package:saldough/features/premium/domain/paywall_trigger.dart';

// Satu-satunya berkas fitur `premium` yang boleh diimpor fitur lain
// (ADR-030 §3.3).

export 'package:saldough/features/premium/domain/paywall_trigger.dart'
    show PaywallTrigger;

/// Input paywall: tempat ia dibuka.
final class PaywallInput extends RouteInput {
  /// Membuat [PaywallInput].
  const PaywallInput(this.trigger);

  /// Pemicu paywall.
  final PaywallTrigger trigger;
}

/// Kunci rute fitur `premium`.
abstract final class PremiumRouteKeys {
  /// Paywall: ajakan masuk akun atau (kelak) berlangganan Plus.
  static const paywall = RouteKey<PaywallInput>('premium.paywall');
}
