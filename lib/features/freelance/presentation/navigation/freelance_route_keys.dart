import 'package:navigation/navigation.dart';

// Satu-satunya berkas fitur `freelance` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3).

/// Kunci rute fitur `freelance`.
abstract final class FreelanceRouteKeys {
  /// Ikhtisar Freelance (FR-FRL-005): dari CATAT → Catat Pemasukan → kartu
  /// Freelance, dan dari ringkasan freelance di Beranda.
  static const overview = RouteKey<EmptyInput>('freelance.overview');
}
