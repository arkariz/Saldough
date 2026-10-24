import 'package:saldough/core/foundation/entitlement/entitlement_limits.dart';

/// Sumber batas dan jatah Plus (ADR-041 §3.6). Implementasinya membaca Remote
/// Config; port ini ada di `core` supaya `Entitlements` dan uji tidak
/// bergantung pada Firebase.
abstract interface class EntitlementConfig {
  /// Batas yang berlaku sekarang. Sebelum server pernah terbaca, atau bila
  /// gagal, [EntitlementLimits.defaults]. Tidak pernah melempar.
  EntitlementLimits get current;

  /// Memancar setiap kali [current] berubah.
  Stream<EntitlementLimits> get changes;

  /// Mengambil nilai terbaru dari server (tunduk batas frekuensi SDK). Galat
  /// ditelan: [current] tetap nilai terakhir yang sah.
  Future<void> refresh();
}
