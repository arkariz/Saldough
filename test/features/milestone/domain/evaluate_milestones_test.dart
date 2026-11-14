import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_def.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_ledger.dart';
import 'package:saldough/features/milestone/domain/repositories/milestone_ports.dart';
import 'package:saldough/features/milestone/domain/usecases/evaluate_milestones.dart';

final class _Store implements MilestoneStore {
  _Store(this.ledger);
  MilestoneLedger ledger;
  int saves = 0;
  bool failSave = false;

  @override
  Future<Either<Failure, MilestoneLedger>> load() async => Right(ledger);

  @override
  Future<Either<Failure, Unit>> save(MilestoneLedger value) async {
    if (failSave) return const Left(SystemFailure(code: FailureCode.unknown, message: 'x'));
    saves++;
    ledger = value;
    return const Right(unit);
  }
}

final class _Facts implements MilestoneFactsSource {
  _Facts(this.result);
  Either<Failure, Set<MilestoneFact>> result;

  @override
  Future<Either<Failure, Set<MilestoneFact>>> read() async => result;
}

void main() {
  final now = DateTime(2026, 11, 14);

  test('menyimpan hanya bila ada yang berubah (idempoten)', () async {
    final store = _Store(const MilestoneLedger(seeded: true));
    final run = EvaluateMilestones(store: store, facts: _Facts(const Right({MilestoneFact.walletExists})), now: () => now);
    expect((await run()).getOrElse((_) => throw StateError('gagal')).newlyEarned, ['wallet_first']);
    await run();
    expect(store.saves, 1);
  });

  test('gagal baca fakta: Left, tidak menyimpan, tidak ada stempel hilang', () async {
    final store = _Store(const MilestoneLedger(seeded: true));
    final run = EvaluateMilestones(store: store, facts: _Facts(const Left(SystemFailure(code: FailureCode.unknown, message: 'x'))), now: () => now);
    expect((await run()).isLeft(), isTrue);
    expect(store.saves, 0);
  });

  test('gagal simpan: Left; evaluasi berikutnya mengulang', () async {
    final store = _Store(const MilestoneLedger(seeded: true))..failSave = true;
    final run = EvaluateMilestones(store: store, facts: _Facts(const Right({MilestoneFact.walletExists})), now: () => now);
    expect((await run()).isLeft(), isTrue);
    store.failSave = false;
    expect((await run()).getOrElse((_) => throw StateError('gagal')).newlyEarned, ['wallet_first']);
  });
}
