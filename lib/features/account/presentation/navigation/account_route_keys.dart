import 'package:navigation/navigation.dart';

// Satu-satunya berkas fitur `account` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3).

/// Kunci rute fitur `account`.
abstract final class AccountRouteKeys {
  /// Layar Akun (ADR-023, ADR-024): dari tombol akun Beranda dan dari ajakan
  /// masuk di akhir onboarding.
  static const page = RouteKey<EmptyInput>('account.page');
}
