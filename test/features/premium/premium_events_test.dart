import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/financial_month/financial_period.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/premium/data/entitlement_cache_store.dart';
import 'package:saldough/features/premium/data/local_entitlements.dart';
import 'package:saldough/features/premium/data/plus_snapshot.dart';
import 'package:saldough/features/premium/data/premium_purchases.dart';
import 'package:saldough/features/premium/data/purchases_gateway.dart';
import 'package:saldough/features/premium/data/quota_store.dart';
import 'package:saldough/features/premium/data/revenuecat_plan_source.dart';
import 'package:saldough/features/premium/data/trial_store.dart';
import 'package:saldough/features/premium/domain/paywall_trigger.dart';
import 'package:saldough/features/premium/domain/purchase_models.dart';

final class _Config implements EntitlementConfig {
  @override
  EntitlementLimits current = EntitlementLimits.fromValues(const {
    'plus_launch_at': '2026-12-01',
    'free_smart_interpretations': '1',
  });
  @override
  Stream<EntitlementLimits> get changes => const Stream.empty();
  @override
  Future<void> refresh() async {}
}

final class _Gateway implements PurchasesGateway {
  BuyResult result = const BuyDone();
  @override
  Future<void> configure() async {}
  @override
  Future<PlusSnapshot?> logIn(String uid, {String? email, String? displayName}) async => null;
  @override
  Future<PlusSnapshot?> logOut() async => null;
  @override
  Future<PlusSnapshot?> fetch() async => null;
  @override
  Future<PlusSnapshot?> restore() async => null;
  @override
  Stream<PlusSnapshot?> get updates => const Stream.empty();
  @override
  Future<List<PlanOption>> options(String offeringId) async => const [];
  @override
  Future<({BuyResult result, PlusSnapshot? snapshot})> purchase(
    PlanOption option,
  ) async => (result: result, snapshot: const PlusSnapshot(isActive: true));
}

/// Peristiwa Plus (ADR-041 §3.12): hanya jenis, paket, pemicu, dan hari.
void main() {
  late List<AnalyticsEvent> events;

  setUp(() {
    events = [];
    AppAnalytics.debugSink = events.add;
  });

  tearDown(() => AppAnalytics.debugSink = null);

  test('nama dan parameter tiap peristiwa', () {
    expect(
      PremiumEvents.trialStarted(days: 24),
      const AnalyticsEvent('trial_started', {'days': 24}),
    );
    expect(
      PremiumEvents.trialMoment(pillar: 'guardian'),
      const AnalyticsEvent('trial_moment', {'pillar': 'guardian'}),
    );
    expect(PremiumEvents.trialValueRecapShown.name, 'trial_value_recap_shown');
    expect(PremiumEvents.trialEnded(outcome: 'lapsed').parameters, {
      'outcome': 'lapsed',
    });
    expect(PremiumEvents.paywallViewed(trigger: 'P2').parameters, {
      'trigger': 'P2',
    });
    expect(
      PremiumEvents.paywallDismissed(trigger: 'limit').name,
      'paywall_dismissed',
    );
    expect(PremiumEvents.purchaseStarted(plan: 'yearly').parameters, {
      'plan': 'yearly',
    });
    expect(
      PremiumEvents.purchaseCompleted(plan: 'yearly_founder').name,
      'purchase_completed',
    );
    expect(PremiumEvents.purchaseFailed(reason: 'network').parameters, {
      'reason': 'network',
    });
    expect(PremiumEvents.purchaseRestored.name, 'purchase_restored');
    expect(PremiumEvents.purchaseRestored.name, isNot('restore_completed'));
    expect(PremiumEvents.plusFeatureUsed(feature: 'ask').parameters, {
      'feature': 'ask',
    });
    expect(
      PremiumEvents.tasteQuotaExhausted(feature: 'smartInterpretation').name,
      'taste_quota_exhausted',
    );
  });

  test(
    'semua parameter hanya teks pendek atau angka: tanpa ID akun, harga, atau nominal',
    () {
      final all = [
        PremiumEvents.trialStarted(days: 14),
        PremiumEvents.paywallViewed(
          trigger: PaywallTrigger.account.analyticsName,
        ),
        PremiumEvents.purchaseStarted(plan: PlusPlanKind.yearlyIntro.id),
        PremiumEvents.purchaseFailed(
          reason: PurchaseFailure.billing.analyticsName,
        ),
      ];
      for (final event in all) {
        expect(
          event.parameters.keys,
          everyElement(
            isIn([
              'days',
              'trigger',
              'plan',
              'reason',
              'pillar',
              'outcome',
              'feature',
            ]),
          ),
        );
      }
    },
  );

  group('pembelian', () {
    late _Gateway gateway;
    late PremiumPurchases purchases;
    const option = PlanOption(
      kind: PlusPlanKind.yearly,
      priceText: 'Rp179.000',
      handle: 'x',
    );

    setUp(() async {
      final storage = InMemoryKeyValueStorage();
      gateway = _Gateway();
      final source = RevenueCatPlanSource(
        gateway: gateway,
        cache: EntitlementCacheStore(storage: storage),
        onChanged: () async {},
      );
      await source.start();
      purchases = PremiumPurchases(
        gateway: gateway,
        source: source,
        trials: TrialStore(storage: storage),
        config: _Config(),
        uid: () => null,
        now: () => DateTime(2026, 12, 10),
      );
    });

    test('berhasil: started lalu completed dengan paketnya', () async {
      await purchases.buy(option);
      expect(events, [
        PremiumEvents.purchaseStarted(plan: 'yearly'),
        PremiumEvents.purchaseCompleted(plan: 'yearly'),
      ]);
    });

    test('gagal: started lalu failed dengan alasannya', () async {
      gateway.result = const BuyFailed(PurchaseFailure.network);
      await purchases.buy(option);
      expect(events, [
        PremiumEvents.purchaseStarted(plan: 'yearly'),
        PremiumEvents.purchaseFailed(reason: 'network'),
      ]);
    });

    test('dibatalkan pengguna: hanya started, bukan kegagalan', () async {
      gateway.result = const BuyCancelled();
      await purchases.buy(option);
      expect(events, [PremiumEvents.purchaseStarted(plan: 'yearly')]);
    });

    test('pulihkan pembelian: purchase_restored', () async {
      await purchases.restore();
      expect(events, [PremiumEvents.purchaseRestored]);
    });
  });

  group('hak', () {
    late LocalEntitlements entitlements;
    final now = DateTime(2026, 12, 10, 9);

    setUp(() {
      final storage = InMemoryKeyValueStorage();
      entitlements = LocalEntitlements(
        config: _Config(),
        trials: TrialStore(storage: storage),
        cache: EntitlementCacheStore(storage: storage),
        quotas: QuotaStore(storage: storage),
        schedule: () =>
            FinancialMonthSchedule.single(const FinancialMonthStart.day(25)),
        now: () => now,
      );
    });

    tearDown(() => entitlements.dispose());

    test(
      'uji coba dimulai sekali: trial_started dengan jumlah harinya',
      () async {
        final account = EntitlementAccount(
          uid: 'u1',
          createdAt: DateTime(2026, 12, 5),
        );
        await entitlements.setAccount(account);
        await entitlements.setAccount(account);
        final started = events.where((e) => e.name == 'trial_started').toList();
        expect(started, [
          PremiumEvents.trialStarted(days: 20),
        ], reason: '5–24 Des = 20 hari, sekali saja');
      },
    );

    test(
      'jatah Gratis habis: taste_quota_exhausted; sebelum habis tidak ada peristiwa',
      () async {
        expect(
          await entitlements.tryUse(PlusFeature.smartInterpretation),
          isTrue,
        );
        expect(events, isEmpty);
        expect(
          await entitlements.tryUse(PlusFeature.smartInterpretation),
          isFalse,
        );
        expect(events, [
          PremiumEvents.tasteQuotaExhausted(feature: 'smartInterpretation'),
        ]);
      },
    );

    test('pengguna Plus memakai fitur: plus_feature_used', () async {
      await entitlements.setAccount(const EntitlementAccount(uid: 'u1'));
      events.clear();
      await entitlements.tryUse(PlusFeature.ask);
      expect(events, [PremiumEvents.plusFeatureUsed(feature: 'ask')]);
    });
  });
}
