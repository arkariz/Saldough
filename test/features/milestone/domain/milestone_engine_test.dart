import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_catalog.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_def.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_ledger.dart';
import 'package:saldough/features/milestone/domain/services/milestone_engine.dart';

MilestoneEvaluation run(MilestoneLedger ledger, Set<MilestoneFact> facts, {Set<String> disabled = const {}}) =>
    evaluateMilestones(
      catalog: milestoneCatalog,
      ledger: ledger,
      facts: facts,
      now: DateTime(2026, 11, 14),
      disabledIds: disabled,
    );

const seeded = MilestoneLedger(seeded: true);

void main() {
  test('katalog: delapan id unik, satu fakta per tonggak (G-2: tanpa volume/nominal)', () {
    expect(milestoneCatalog, hasLength(8));
    expect({for (final d in milestoneCatalog) d.id}, hasLength(8));
    expect({for (final d in milestoneCatalog) d.fact}, hasLength(8));
    expect(milestoneCatalog.where((d) => d.revealOnUse).map((d) => d.id), ['inbox_clear', 'freelance_paid']);
  });

  test('fakta benar → diraih, dengan perayaan (bukan diam-diam) sesudah seeded', () {
    final r = run(seeded, {MilestoneFact.walletExists});
    expect(r.newlyEarned, ['wallet_first']);
    expect(r.quiet, isFalse);
    expect(r.ledger.earned['wallet_first']!.earnedAt, DateTime(2026, 11, 14));
  });

  test('G-3 idempoten: mengulang tidak mengubah apa pun', () {
    final first = run(seeded, {MilestoneFact.walletExists}).ledger;
    final again = run(first, {MilestoneFact.walletExists});
    expect(again.newlyEarned, isEmpty);
    expect(again.ledger, same(first));
  });

  test('G-1: yang sudah diraih tidak dicabut saat fakta tidak lagi benar', () {
    final first = run(seeded, {MilestoneFact.walletExists}).ledger;
    final later = run(first, {});
    expect(later.ledger.has('wallet_first'), isTrue);
  });

  test('G-6: evaluasi pertama memasukkan semua yang memenuhi syarat diam-diam', () {
    final r = run(MilestoneLedger.empty, {MilestoneFact.walletExists, MilestoneFact.recordExists});
    expect(r.quiet, isTrue);
    expect(r.newlyEarned, ['wallet_first', 'record_first']);
    expect(r.ledger.earned.values.every((e) => e.quiet), isTrue);
    expect(r.ledger.seeded, isTrue);
    expect(r.ledger.introShown, isFalse);
  });

  test('G-6: pengguna baru tanpa fakta tetap ditandai seeded; sesudahnya tidak diam-diam', () {
    final r = run(MilestoneLedger.empty, {});
    expect(r.ledger.seeded, isTrue);
    expect(run(r.ledger, {MilestoneFact.backupDone}).quiet, isFalse);
  });

  test('saklar jarak jauh menahan tonggak baru tetapi tidak mencabut yang ada', () {
    final held = run(seeded, {MilestoneFact.walletExists}, disabled: {'wallet_first'});
    expect(held.newlyEarned, isEmpty);
    final earned = run(seeded, {MilestoneFact.walletExists}).ledger;
    expect(run(earned, {MilestoneFact.walletExists}, disabled: {'wallet_first'}).ledger.has('wallet_first'), isTrue);
  });

  test('beberapa tonggak sekaligus: urut katalog', () {
    final r = run(seeded, {MilestoneFact.freelancePaid, MilestoneFact.walletExists});
    expect(r.newlyEarned, ['wallet_first', 'freelance_paid']);
  });
}
