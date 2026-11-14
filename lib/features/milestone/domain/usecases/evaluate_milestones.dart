import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_catalog.dart';
import 'package:saldough/features/milestone/domain/repositories/milestone_ports.dart';
import 'package:saldough/features/milestone/domain/services/milestone_engine.dart';

/// Membaca fakta, menghitung stempel baru, dan menyimpannya (ADR-046 §3.4).
///
/// Idempoten dan tidak melempar: kegagalan baca fakta atau simpan dikembalikan
/// sebagai `Left` supaya pemanggil mengabaikannya diam-diam; evaluasi berikutnya
/// mengulang (G-5). Tidak ada yang disimpan bila tidak ada yang berubah.
final class EvaluateMilestones {
  /// Membuat [EvaluateMilestones].
  const EvaluateMilestones({required this._store, required this._facts, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final MilestoneStore _store;
  final MilestoneFactsSource _facts;
  final DateTime Function() _now;

  /// Menjalankan satu evaluasi. [disabledIds] dari saklar jarak jauh.
  Future<Either<Failure, MilestoneEvaluation>> call({Set<String> disabledIds = const {}}) async {
    final ledger = await _store.load();
    final facts = await _facts.read();
    return ledger.fold(Left.new, (current) => facts.fold(Left.new, (known) async {
      final result = evaluateMilestones(
        catalog: milestoneCatalog,
        ledger: current,
        facts: known,
        now: _now(),
        disabledIds: disabledIds,
      );
      if (result.ledger == current) return Right(result);
      return (await _store.save(result.ledger)).map((_) => result);
    }));
  }
}
