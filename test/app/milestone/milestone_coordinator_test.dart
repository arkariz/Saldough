import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/app/milestone/milestone_coordinator.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_def.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_ledger.dart';
import 'package:saldough/features/milestone/domain/repositories/milestone_ports.dart';
import 'package:saldough/features/milestone/domain/services/celebration_policy.dart';
import 'package:saldough/features/milestone/domain/usecases/evaluate_milestones.dart';

final class _Store implements MilestoneStore {
  _Store(this.ledger);
  MilestoneLedger ledger;

  @override
  Future<Either<Failure, MilestoneLedger>> load() async => Right(ledger);

  @override
  Future<Either<Failure, Unit>> save(MilestoneLedger value) async {
    ledger = value;
    return const Right(unit);
  }
}

final class _Facts implements MilestoneFactsSource {
  Set<MilestoneFact> facts = {};

  @override
  Future<Either<Failure, Set<MilestoneFact>>> read() async => Right(facts);
}

void main() {
  late _Store store;
  late _Facts facts;
  late StreamController<void> signals;
  late MilestoneCoordinator coordinator;
  late List<CelebrationPlan> plans;

  setUp(() {
    store = _Store(const MilestoneLedger(seeded: true, introShown: true));
    facts = _Facts();
    signals = StreamController<void>.broadcast();
    coordinator = MilestoneCoordinator(
      evaluate: EvaluateMilestones(store: store, facts: facts, now: () => DateTime(2026, 11, 14)),
      store: store,
      signals: signals.stream,
      debounce: Duration.zero,
    );
    plans = [];
    coordinator.celebrations.listen(plans.add);
  });

  tearDown(() async {
    await coordinator.stop();
    await signals.close();
  });

  test('stempel baru dan boleh dirayakan: snackbar, dan catatan terbarui', () async {
    coordinator.canCelebrate = () => true;
    facts.facts = {MilestoneFact.walletExists};
    await coordinator.start();
    await Future<void>.delayed(Duration.zero);
    expect(plans, [const CelebrationPlan(CelebrationKind.snackbar, ['wallet_first'])]);
    expect(coordinator.ledger.value.has('wallet_first'), isTrue);
  });

  test('terhalang: stempel tetap diraih dan satu perayaan menunggu, tampil begitu bebas halangan', () async {
    facts.facts = {MilestoneFact.walletExists};
    await coordinator.start();
    await Future<void>.delayed(Duration.zero);
    expect(plans, isEmpty);
    expect(coordinator.ledger.value.has('wallet_first'), isTrue);
    expect(hasUnseenStamps(coordinator.ledger.value), isTrue);
    expect(coordinator.pending.value, ['wallet_first']);

    coordinator.retryPending();
    expect(plans, isEmpty, reason: 'masih terhalang');

    coordinator
      ..canCelebrate = (() => true)
      ..retryPending();
    await Future<void>.delayed(Duration.zero);
    expect(plans, [const CelebrationPlan(CelebrationKind.snackbar, ['wallet_first'])]);
    expect(coordinator.pending.value, isEmpty);
    coordinator.retryPending();
    await Future<void>.delayed(Duration.zero);
    expect(plans, hasLength(1), reason: 'sekali saja');
  });

  test('beberapa stempel tertahan digabung menjadi satu perayaan (G-4)', () async {
    facts.facts = {MilestoneFact.walletExists};
    await coordinator.start();
    facts.facts = {MilestoneFact.walletExists, MilestoneFact.recordExists};
    await coordinator.evaluate();
    expect(coordinator.pending.value, ['wallet_first', 'record_first']);
    coordinator
      ..canCelebrate = (() => true)
      ..retryPending();
    await Future<void>.delayed(Duration.zero);
    expect(plans.single.kind, CelebrationKind.snackbar);
    expect(plans.single.ids, ['wallet_first', 'record_first']);
  });

  test('membuka Buku Stempel atau mematikan perayaan membatalkan yang tertahan', () async {
    facts.facts = {MilestoneFact.walletExists};
    await coordinator.start();
    expect(coordinator.pending.value, isNotEmpty);
    await coordinator.markAllSeen();
    expect(coordinator.pending.value, isEmpty);

    facts.facts = {MilestoneFact.walletExists, MilestoneFact.recordExists};
    await coordinator.evaluate();
    expect(coordinator.pending.value, ['record_first']);
    await coordinator.setCelebrationEnabled(enabled: false);
    expect(coordinator.pending.value, isEmpty);
    coordinator
      ..canCelebrate = (() => true)
      ..retryPending();
    await Future<void>.delayed(Duration.zero);
    expect(plans, isEmpty);
  });

  test('pemasukan pengguna lama (quiet) tidak pernah menjadi perayaan tertahan', () async {
    store.ledger = MilestoneLedger.empty;
    facts.facts = {MilestoneFact.walletExists, MilestoneFact.recordExists};
    await coordinator.start();
    expect(coordinator.pending.value, isEmpty);
  });

  test('sinyal memicu evaluasi (digabung)', () async {
    coordinator.canCelebrate = () => true;
    await coordinator.start();
    facts.facts = {MilestoneFact.recordExists};
    signals
      ..add(null)
      ..add(null);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(plans, hasLength(1));
    expect(plans.single.ids, ['record_first']);
  });

  test('markAllSeen menghapus titik; markIntroShown dan sakelar disimpan', () async {
    facts.facts = {MilestoneFact.walletExists};
    await coordinator.start();
    await coordinator.markAllSeen();
    expect(hasUnseenStamps(coordinator.ledger.value), isFalse);
    await coordinator.setCelebrationEnabled(enabled: false);
    expect(store.ledger.celebrationEnabled, isFalse);
    await coordinator.setCelebrationEnabled(enabled: true);
    expect(store.ledger.has('wallet_first'), isTrue, reason: 'menyalakan lagi tidak mengubah stempel (G-8)');
  });

  test('pengguna lama: banner berbasis keadaan sampai pengenalan ditandai', () async {
    store.ledger = MilestoneLedger.empty;
    facts.facts = {MilestoneFact.walletExists, MilestoneFact.recordExists};
    await coordinator.start();
    expect(legacyBannerVisible(coordinator.ledger.value), isTrue);
    await coordinator.markIntroShown();
    expect(legacyBannerVisible(coordinator.ledger.value), isFalse);
  });

  test('saklar jarak jauh menahan stempel baru tetapi tidak mencabut yang ada', () async {
    facts.facts = {MilestoneFact.walletExists};
    store.ledger = MilestoneLedger(
      earned: {'record_first': EarnedMilestone(id: 'record_first', earnedAt: DateTime(2026))},
      seeded: true,
      introShown: true,
    );
    final held = MilestoneCoordinator(
      evaluate: EvaluateMilestones(store: store, facts: facts),
      store: store,
      signals: const Stream<void>.empty(),
      disabledIds: () => {'wallet_first'},
    );
    await held.start();
    expect(held.ledger.value.has('wallet_first'), isFalse);
    expect(held.ledger.value.has('record_first'), isTrue);
    await held.stop();
  });

  test('analitik: milestone_earned per stempel, quiet untuk pemasukan pengguna lama', () async {
    final logged = <AnalyticsEvent>[];
    AppAnalytics.debugSink = logged.add;
    addTearDown(() => AppAnalytics.debugSink = null);
    store.ledger = MilestoneLedger.empty;
    facts.facts = {MilestoneFact.walletExists};
    await coordinator.start();
    expect(logged, [MilestoneEvents.earned(id: 'wallet_first', quiet: true)]);
    facts.facts = {MilestoneFact.walletExists, MilestoneFact.recordExists};
    await coordinator.evaluate();
    expect(logged.last, MilestoneEvents.earned(id: 'record_first', quiet: false));
  });

  test('absorbIntoCover: stempel periode dilipat ke sampul, dibuang dari perayaan tertahan dan dianggap dilihat (BP-13)', () async {
    facts.facts = {MilestoneFact.walletExists, MilestoneFact.tidyPeriodClosed};
    await coordinator.start();
    expect(coordinator.pending.value, ['wallet_first', 'period_tidy']);
    await coordinator.absorbIntoCover({'period_tidy'});
    expect(coordinator.pending.value, ['wallet_first']);
    expect(coordinator.ledger.value.earned['period_tidy']!.seen, isTrue);
    expect(coordinator.ledger.value.earned['wallet_first']!.seen, isFalse);
  });
}
