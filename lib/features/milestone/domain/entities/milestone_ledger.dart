import 'package:dependencies/dependencies.dart';

/// Satu stempel yang sudah diraih. Tidak pernah dicabut (G-1).
final class EarnedMilestone extends Equatable {
  /// Membuat [EarnedMilestone].
  const EarnedMilestone({required this.id, required this.earnedAt, this.seen = false, this.quiet = false});

  /// Id katalog.
  final String id;

  /// Saat diraih.
  final DateTime earnedAt;

  /// Sudah dilihat di Buku Stempel (titik kecil hilang).
  final bool seen;

  /// Dimasukkan diam-diam (G-6), tanpa perayaan.
  final bool quiet;

  /// Salinan dengan [seen] diganti.
  EarnedMilestone markSeen() => EarnedMilestone(id: id, earnedAt: earnedAt, seen: true, quiet: quiet);

  @override
  List<Object?> get props => [id, earnedAt, seen, quiet];
}

/// Catatan stempel di perangkat (ADR-046 §3.5): yang diraih, penanda
/// pengenalan pengguna lama, dan sakelar perayaan. Bukan data keuangan.
final class MilestoneLedger extends Equatable {
  /// Membuat [MilestoneLedger].
  const MilestoneLedger({
    this.earned = const {},
    this.seeded = false,
    this.introShown = false,
    this.celebrationEnabled = true,
  });

  /// Kosong: belum dievaluasi sama sekali.
  static const empty = MilestoneLedger();

  /// Id → stempel diraih.
  final Map<String, EarnedMilestone> earned;

  /// Evaluasi pertama sudah berjalan (G-6).
  final bool seeded;

  /// Banner pengenalan pengguna lama sudah tampil.
  final bool introShown;

  /// Sakelar Perayaan stempel (G-8).
  final bool celebrationEnabled;

  /// Id sudah diraih.
  bool has(String id) => earned.containsKey(id);

  /// Salinan dengan perubahan.
  MilestoneLedger copyWith({
    Map<String, EarnedMilestone>? earned,
    bool? seeded,
    bool? introShown,
    bool? celebrationEnabled,
  }) => MilestoneLedger(
    earned: earned ?? this.earned,
    seeded: seeded ?? this.seeded,
    introShown: introShown ?? this.introShown,
    celebrationEnabled: celebrationEnabled ?? this.celebrationEnabled,
  );

  @override
  List<Object?> get props => [earned, seeded, introShown, celebrationEnabled];
}
