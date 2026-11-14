import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_def.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_ledger.dart';

/// Penyimpanan [MilestoneLedger] (ADR-046 §3.5).
abstract interface class MilestoneStore {
  /// Membaca catatan; kosong bila belum pernah ditulis.
  Future<Either<Failure, MilestoneLedger>> load();

  /// Menulis ganti seluruh catatan.
  Future<Either<Failure, Unit>> save(MilestoneLedger ledger);
}

/// Sumber fakta (ADR-046 §3.1). Diimplementasi di `lib/app/milestone/`.
// ignore: one_member_abstracts, port ke akar komposisi (ADR-046 §3.1).
abstract interface class MilestoneFactsSource {
  /// Himpunan fakta yang **benar sekarang**.
  Future<Either<Failure, Set<MilestoneFact>>> read();
}
