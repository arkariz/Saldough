import 'package:navigation/navigation.dart';
import 'package:saldough/features/premium/domain/paywall_trigger.dart';
import 'package:saldough/features/premium/domain/plus_moments.dart';
import 'package:saldough/features/premium/domain/trial_gift.dart';

// Satu-satunya berkas fitur `premium` yang boleh diimpor fitur lain
// (ADR-030 §3.3).

export 'package:saldough/features/premium/domain/paywall_trigger.dart'
    show PaywallTrigger;
export 'package:saldough/features/premium/domain/trial_gift.dart' show TrialGiftInfo;

/// Input paywall: tempat ia dibuka.
final class PaywallInput extends RouteInput {
  /// Membuat [PaywallInput].
  const PaywallInput(this.trigger);

  /// Pemicu paywall.
  final PaywallTrigger trigger;
}

/// Input halaman "Yang dikerjakan Plus": [fromPaywall] = dibuka dari paywall,
/// jadi "Lihat paket" cukup kembali ke sana.
final class PlusFeaturesInput extends RouteInput {
  /// Membuat [PlusFeaturesInput].
  const PlusFeaturesInput({this.fromPaywall = false});

  /// Dibuka dari paywall.
  final bool fromPaywall;
}

/// Input layar hadiah uji coba.
final class TrialGiftInput extends RouteInput {
  /// Membuat [TrialGiftInput].
  const TrialGiftInput(this.info);

  /// Keadaan uji coba saat layar dibuka.
  final TrialGiftInfo info;
}

/// Input layar turun ke Gratis sesudah uji coba.
final class DowngradeInput extends RouteInput {
  /// Membuat [DowngradeInput].
  const DowngradeInput(this.data);

  /// Isi layar.
  final PlusDowngrade data;
}

/// Kunci rute fitur `premium`.
abstract final class PremiumRouteKeys {
  /// Paywall: ajakan masuk akun atau (kelak) berlangganan Plus.
  static const paywall = RouteKey<PaywallInput>('premium.paywall');

  /// Halaman "Yang dikerjakan Plus" (enam pilar dan yang tetap gratis).
  static const features = RouteKey<PlusFeaturesInput>('premium.features');

  /// Layar hadiah uji coba (D-1), dibuka sekali oleh `TrialGiftHost`.
  static const trialGift = RouteKey<TrialGiftInput>('premium.trialGift');

  /// Layar turun ke Gratis sesudah uji coba (D-8).
  static const downgrade = RouteKey<DowngradeInput>('premium.downgrade');
}
