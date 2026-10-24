import 'package:flutter/foundation.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';

/// Paket yang berlaku sekarang, untuk gerbang tampilan yang cukup tahu "Plus
/// atau bukan" (ADR-041 §3.8). Pola yang sama dengan `ActiveCurrency` dan
/// `ActiveFinancialMonth`: diisi akar komposisi dari `Entitlements.changes`,
/// dikembalikan ke Gratis saat boot ulang. Gerbang yang butuh batas atau
/// jatah memakai `Entitlements` langsung.
///
/// Bawaan [FreePlan]: bila kabelnya terlewat, yang terkunci tetap terkunci,
/// bukan terbuka. Uji yang butuh Plus mengisi [notifier] dan mendaftarkan `addTearDown(ActivePlan.reset)`.
abstract final class ActivePlan {
  ActivePlan._();

  /// Pemegang nilai.
  static final ValueNotifier<PlanState> notifier = ValueNotifier(const FreePlan());

  /// Batas dan jatah yang berlaku (Remote Config, bawaan lokal); gerbang
  /// tampilan membaca batas Gratis di sini.
  static final ValueNotifier<EntitlementLimits> limits = ValueNotifier(EntitlementLimits.defaults);

  /// Paket berlaku.
  static PlanState get state => notifier.value;

  /// Fitur Plus terbuka (uji coba atau Plus).
  static bool get isPlus => notifier.value.isPlus;

  /// Mengembalikan ke Gratis (boot ulang).
  static void reset() {
    notifier.value = const FreePlan();
    limits.value = EntitlementLimits.defaults;
  }
}
