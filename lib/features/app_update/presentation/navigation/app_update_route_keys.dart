import 'package:navigation/navigation.dart';

// Satu-satunya berkas fitur `app_update` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3).

/// Kunci rute fitur `app_update` (ADR-039).
abstract final class AppUpdateRouteKeys {
  /// Layar "Apa yang baru" dengan tindakan pembaruan, dari baris Versi
  /// aplikasi di layar Akun (APP_UPDATE F4).
  static const notes = RouteKey<EmptyInput>('appUpdate.notes');
}
