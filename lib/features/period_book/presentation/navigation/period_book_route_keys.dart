import 'package:navigation/navigation.dart';

// Satu-satunya berkas fitur `period_book` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3).

/// Input ritual Tutup buku.
final class RitualInput extends RouteInput {
  /// Membuat [RitualInput].
  const RitualInput({required this.periodId});

  /// Id periode (`periodBookIdOf`, tanggal awal `YYYY-MM-DD`).
  final String periodId;
}

/// Kunci rute fitur `period_book` (ADR-045).
abstract final class PeriodBookRouteKeys {
  /// Ritual Tutup buku tiga langkah (D4, T-27.5), dari kartu Beranda atau Rak Buku.
  static const ritual = RouteKey<RitualInput>('periodBook.ritual');
}
