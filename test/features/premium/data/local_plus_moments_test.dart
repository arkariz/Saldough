import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/premium/data/entitlement_cache_store.dart';
import 'package:saldough/features/premium/data/local_entitlements.dart';
import 'package:saldough/features/premium/data/local_plus_moments.dart';
import 'package:saldough/features/premium/data/quota_store.dart';
import 'package:saldough/features/premium/data/trial_store.dart';
import 'package:saldough/features/premium/domain/offering_policy.dart';
import 'package:saldough/features/premium/domain/plus_moments.dart';
import 'package:saldough/features/premium/domain/purchase_models.dart';

import '../../../helpers/fake_plus_purchasing.dart';

final class _Config implements EntitlementConfig {
  @override
  EntitlementLimits current = EntitlementLimits.fromValues(const {'plus_launch_at': '2026-11-01'});

  @override
  Stream<EntitlementLimits> get changes => const Stream.empty();

  @override
  Future<void> refresh() async {}
}

final class _Usage implements PlusUsage {
  int sources = 3;
  int rules = 4;
  int recorded = 14;

  @override
  Future<int> notificationSources() async => sources;

  @override
  Future<int> autoRecordRules() async => rules;

  @override
  Future<int> autoRecordedSince(DateTime since) async => recorded;
}

/// Momen terjadwal uji coba (FREEMIUM_PAYWALL §8.2): kartu dan layar turun.
void main() {
  late InMemoryKeyValueStorage storage;
  late LocalEntitlements entitlements;
  late LocalPlusMoments moments;
  late FakePlusPurchasing purchasing;
  late _Usage usage;
  late DateTime now;
  late List<AnalyticsEvent> events;

  setUp(() async {
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial;
    events = [];
    AppAnalytics.debugSink = events.add;
    addTearDown(() {
      AppAnalytics.debugSink = null;
      ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial;
    });
    storage = InMemoryKeyValueStorage();
    now = DateTime(2026, 11, 3, 9);
    entitlements = LocalEntitlements(
      config: _Config(),
      trials: TrialStore(storage: storage),
      cache: EntitlementCacheStore(storage: storage),
      quotas: QuotaStore(storage: storage),
      schedule: () => ActiveFinancialMonth.schedule,
      now: () => now,
    );
    addTearDown(entitlements.dispose);
    purchasing = FakePlusPurchasing();
    usage = _Usage();
    moments = LocalPlusMoments(
      entitlements: entitlements,
      trials: TrialStore(storage: storage),
      usage: usage,
      purchasing: purchasing,
      now: () => now,
    );
    await entitlements.setAccount(EntitlementAccount(uid: 'u1', createdAt: DateTime(2026, 11, 2)));
  });

  group('kartu', () {
    test('uji coba jauh dari akhir: tanpa kartu; H-3: rekap dengan angka, dicatat sekali', () async {
      expect(await moments.card(), isNull);
      now = DateTime(2026, 11, 27, 9);
      final card = await moments.card();
      expect(card, isA<PlusRecapCard>());
      expect((card! as PlusRecapCard).recorded, 14);
      await moments.card();
      expect(events.where((e) => e.name == 'trial_value_recap_shown'), hasLength(1));
    });

    test('rekap ditutup tidak muncul lagi', () async {
      now = DateTime(2026, 11, 28);
      await moments.dismiss((await moments.card())!);
      expect(await moments.card(), isNull);
    });

    test('Gratis dengan jatah tafsir habis: kartu konteks; ditutup per periode', () async {
      await entitlements.setAccount(null);
      expect(entitlements.current, const FreePlan());
      expect(await moments.card(), isNull);
      for (var i = 0; i < entitlements.limits.freeSmartInterpretations; i++) {
        expect(await entitlements.tryUse(PlusFeature.smartInterpretation), isTrue);
      }
      final card = await moments.card();
      expect(card, isA<PlusContextCard>());
      await moments.dismiss(card!);
      expect(await moments.card(), isNull);
      now = DateTime(2026, 12, 3);
      expect(await moments.card(), isNull, reason: 'periode baru: jatah baru, belum habis');
    });
  });

  group('layar turun', () {
    test('selama uji coba: tidak ada', () async {
      expect(await moments.downgrade(), isNull);
    });

    test('sesudah uji coba tanpa membeli: angka pemakai dan penawaran; sekali saja', () async {
      now = DateTime(2026, 12, 2);
      await entitlements.recompute();
      expect(entitlements.current, isA<FreePlan>());
      purchasing.plans = const OfferedPlans(
        offering: OfferingId.postTrial,
        options: [PlanOption(kind: PlusPlanKind.yearlyIntro, priceText: 'Rp129.000', handle: 'i')],
      );
      final data = await moments.downgrade();
      expect(data!.sources, 3);
      expect(data.autoRules, 4);
      expect(data.freePeriods, 6);
      expect(data.offer, isNotNull);
      await moments.markDowngradeShown();
      expect(await moments.downgrade(), isNull);
      expect(events.where((e) => e.name == 'trial_ended' && e.parameters['outcome'] == 'lapsed'), hasLength(1));
    });

    test('tanpa penawaran 48 jam: tanpa kartu penawaran', () async {
      now = DateTime(2026, 12, 20);
      await entitlements.recompute();
      expect((await moments.downgrade())!.offer, isNull);
    });
  });
}
