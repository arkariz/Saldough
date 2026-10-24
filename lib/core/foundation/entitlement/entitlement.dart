/// Barrel hak Plus (ADR-041 §3.1). Tidak mengimpor SDK pembelian, Firebase,
/// maupun fitur; adaptornya di `features/premium/data/` dan `lib/app/premium/`.
library;

export 'entitlement_limits.dart';
export 'entitlement_resolver.dart';
export 'plan_state.dart';
export 'plus_feature.dart';
export 'trial_rules.dart';
