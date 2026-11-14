import 'package:navigation/navigation.dart';

// Satu-satunya berkas fitur `milestone` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3).

/// Kunci rute fitur `milestone` (ADR-046).
abstract final class MilestoneRouteKeys {
  /// Layar Buku Stempel (Akun › Buku Stempel, T-28.5).
  static const book = RouteKey<EmptyInput>('milestone.book');
}
