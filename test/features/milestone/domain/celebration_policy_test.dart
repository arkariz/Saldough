import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_ledger.dart';
import 'package:saldough/features/milestone/domain/services/celebration_policy.dart';
import 'package:saldough/features/milestone/domain/services/milestone_engine.dart';

MilestoneLedger ledger({
  bool enabled = true,
  bool intro = true,
  List<String> earned = const ['wallet_first'],
  bool seen = false,
}) => MilestoneLedger(
  earned: {for (final id in earned) id: EarnedMilestone(id: id, earnedAt: DateTime(2026, 11, 14), seen: seen)},
  seeded: true,
  introShown: intro,
  celebrationEnabled: enabled,
);

MilestoneEvaluation eval(MilestoneLedger l, List<String> newly, {bool quiet = false}) =>
    MilestoneEvaluation(ledger: l, newlyEarned: newly, quiet: quiet);

void main() {
  test('satu stempel baru: snackbar', () {
    final plan = planCelebration(evaluation: eval(ledger(), ['wallet_first']), blocked: false);
    expect(plan, const CelebrationPlan(CelebrationKind.snackbar, ['wallet_first']));
  });

  test('beberapa stempel digabung menjadi satu snackbar (G-4)', () {
    final l = ledger(earned: ['wallet_first', 'record_first']);
    final plan = planCelebration(evaluation: eval(l, ['wallet_first', 'record_first']), blocked: false);
    expect(plan.kind, CelebrationKind.snackbar);
    expect(plan.ids, ['wallet_first', 'record_first']);
  });

  test('stempel pertama sepanjang masa: lembar pengenalan, bukan snackbar', () {
    final plan = planCelebration(evaluation: eval(ledger(intro: false), ['wallet_first']), blocked: false);
    expect(plan.kind, CelebrationKind.firstSheet);
    expect(plan.ids, ['wallet_first']);
  });

  test('terhalang: tidak ada perayaan yang menunggu (G-4)', () {
    expect(planCelebration(evaluation: eval(ledger(), ['wallet_first']), blocked: true), CelebrationPlan.none);
  });

  test('sakelar mati: tidak ada apa pun (G-8)', () {
    final l = ledger(enabled: false);
    expect(planCelebration(evaluation: eval(l, ['wallet_first']), blocked: false), CelebrationPlan.none);
    expect(planCelebration(evaluation: eval(l, ['wallet_first'], quiet: true), blocked: false), CelebrationPlan.none);
  });

  test('pengguna lama (G-6): satu banner, tanpa perayaan per stempel', () {
    final l = ledger(intro: false, earned: ['wallet_first', 'record_first']);
    final plan = planCelebration(evaluation: eval(l, ['wallet_first', 'record_first'], quiet: true), blocked: false);
    expect(plan, const CelebrationPlan(CelebrationKind.legacyBanner));
  });

  test('banner pengguna lama hanya sekali dan hanya bila ada yang masuk', () {
    final shown = ledger(earned: ['wallet_first']);
    expect(planCelebration(evaluation: eval(shown, ['wallet_first'], quiet: true), blocked: false), CelebrationPlan.none);
    final empty = ledger(intro: false, earned: []);
    expect(planCelebration(evaluation: eval(empty, [], quiet: true), blocked: false), CelebrationPlan.none);
  });

  test('evaluasi tanpa yang baru: tidak ada perayaan', () {
    expect(planCelebration(evaluation: eval(ledger(), []), blocked: false), CelebrationPlan.none);
  });

  test('titik belum dilihat: hanya bila menyala dan ada yang belum dilihat', () {
    expect(hasUnseenStamps(ledger()), isTrue);
    expect(hasUnseenStamps(ledger(seen: true)), isFalse);
    expect(hasUnseenStamps(ledger(enabled: false)), isFalse);
  });
}
