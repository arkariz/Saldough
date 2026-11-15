import 'package:navigation/navigation.dart';

// Satu-satunya berkas fitur `milestone` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3).

/// Dari mana Buku Stempel dibuka, untuk analitik (GAMIFICATION §10).
enum StampBookSource {
  /// Baris Akun › Buku Stempel.
  account,

  /// Aksi Lihat di snackbar perayaan.
  celebration,

  /// Lembar pengenalan atau banner pengguna lama.
  intro,
}

/// Input layar Buku Stempel.
final class StampBookInput extends RouteInput {
  /// Membuat [StampBookInput].
  const StampBookInput({this.source = StampBookSource.account});

  /// Asal pembukaan.
  final StampBookSource source;
}

/// Kunci rute fitur `milestone` (ADR-046).
abstract final class MilestoneRouteKeys {
  /// Layar Buku Stempel (Akun › Buku Stempel, T-28.5).
  static const book = RouteKey<StampBookInput>('milestone.book');
}
