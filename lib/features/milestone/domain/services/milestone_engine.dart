import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_def.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_ledger.dart';

/// Hasil satu evaluasi.
final class MilestoneEvaluation extends Equatable {
  /// Membuat [MilestoneEvaluation].
  const MilestoneEvaluation({required this.ledger, this.newlyEarned = const [], this.quiet = false});

  /// Catatan sesudah evaluasi.
  final MilestoneLedger ledger;

  /// Id yang baru diraih pada evaluasi ini, urut katalog.
  final List<String> newlyEarned;

  /// Pemasukan pengguna lama (G-6): tanpa perayaan satu per satu.
  final bool quiet;

  @override
  List<Object?> get props => [ledger, newlyEarned, quiet];
}

/// Mesin evaluasi murni (ADR-046 §3.4). Tanpa penyimpanan, tanpa jam global.
///
/// - G-1: yang sudah diraih tidak pernah dicabut, berapa pun [facts] sekarang.
/// - G-3: satu tonggak paling banyak sekali; mengulang tidak mengubah apa pun.
/// - G-6: evaluasi pertama memasukkan yang memenuhi syarat diam-diam.
/// - [disabledIds] (saklar jarak jauh) menahan tonggak baru, tidak mencabut.
MilestoneEvaluation evaluateMilestones({
  required List<MilestoneDef> catalog,
  required MilestoneLedger ledger,
  required Set<MilestoneFact> facts,
  required DateTime now,
  Set<String> disabledIds = const {},
}) {
  final quiet = !ledger.seeded;
  final newly = <String>[];
  final earned = {...ledger.earned};
  for (final def in catalog) {
    if (ledger.has(def.id) || disabledIds.contains(def.id) || !facts.contains(def.fact)) continue;
    earned[def.id] = EarnedMilestone(id: def.id, earnedAt: now, quiet: quiet);
    newly.add(def.id);
  }
  if (newly.isEmpty && ledger.seeded) return MilestoneEvaluation(ledger: ledger);
  return MilestoneEvaluation(
    ledger: ledger.copyWith(earned: earned, seeded: true),
    newlyEarned: newly,
    quiet: quiet,
  );
}
