import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:purchases_flutter/purchases_flutter.dart' show PurchasesErrorCode;
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/premium/data/entitlement_cache_store.dart';
import 'package:saldough/features/premium/data/plus_snapshot.dart';
import 'package:saldough/features/premium/data/premium_purchases.dart';
import 'package:saldough/features/premium/data/purchases_gateway.dart';
import 'package:saldough/features/premium/data/revenuecat_plan_source.dart';
import 'package:saldough/features/premium/data/trial_store.dart';
import 'package:saldough/features/premium/domain/offering_policy.dart';
import 'package:saldough/features/premium/domain/purchase_models.dart';

final class _Gateway implements PurchasesGateway {
  final offerings = <String, List<PlanOption>>{};
  final asked = <String>[];
  BuyResult result = const BuyDone();
  PlusSnapshot? snapshot;
  bool throwOptions = false;
  bool throwPurchase = false;
  final calls = <String>[];

  @override
  Future<void> configure() async {}
  @override
  Future<PlusSnapshot?> logIn(String uid) async => snapshot;
  @override
  Future<PlusSnapshot?> logOut() async => snapshot;
  @override
  Future<PlusSnapshot?> fetch() async => snapshot;
  @override
  Future<PlusSnapshot?> restore() async {
    calls.add('restore');
    return snapshot;
  }

  @override
  Stream<PlusSnapshot?> get updates => const Stream.empty();

  @override
  Future<List<PlanOption>> options(String offeringId) async {
    asked.add(offeringId);
    if (throwOptions) throw StateError('luring');
    return offerings[offeringId] ?? const [];
  }

  @override
  Future<({BuyResult result, PlusSnapshot? snapshot})> purchase(
    PlanOption option,
  ) async {
    if (throwPurchase) throw StateError('SDK');
    return (result: result, snapshot: snapshot);
  }
}

final class _Config implements EntitlementConfig {
  _Config(this.current);
  @override
  EntitlementLimits current;
  @override
  Stream<EntitlementLimits> get changes => const Stream.empty();
  @override
  Future<void> refresh() async {}
}

PlanOption _opt(PlusPlanKind kind, String price) =>
    PlanOption(kind: kind, priceText: price, handle: kind.id);

/// Beli dan pulihkan (ADR-041 §3.5, P-9).
void main() {
  late _Gateway gateway;
  late EntitlementCacheStore cache;
  late TrialStore trials;
  late RevenueCatPlanSource source;
  late _Config config;
  late DateTime now;
  String? uid;
  late PremiumPurchases purchases;

  EntitlementLimits limits(Map<String, String> values) =>
      EntitlementLimits.fromValues(values);

  setUp(() async {
    final storage = InMemoryKeyValueStorage();
    gateway = _Gateway()
      ..offerings['default'] = [
        _opt(PlusPlanKind.yearly, 'Rp179.000'),
        _opt(PlusPlanKind.monthly, 'Rp25.000'),
      ]
      ..offerings['founder'] = [
        _opt(PlusPlanKind.yearlyFounder, 'Rp129.000'),
        _opt(PlusPlanKind.monthly, 'Rp25.000'),
      ]
      ..offerings['post_trial'] = [
        _opt(PlusPlanKind.yearlyIntro, 'Rp129.000'),
        _opt(PlusPlanKind.monthly, 'Rp25.000'),
      ];
    cache = EntitlementCacheStore(storage: storage);
    trials = TrialStore(storage: storage);
    now = DateTime(2026, 12, 10, 9);
    uid = null;
    config = _Config(limits({'plus_launch_at': '2026-12-01'}));
    source = RevenueCatPlanSource(
      gateway: gateway,
      cache: cache,
      onChanged: () async {},
      now: () => now,
    );
    await source.start();
    purchases = PremiumPurchases(
      gateway: gateway,
      source: source,
      trials: trials,
      config: config,
      uid: () => uid,
      now: () => now,
    );
  });

  tearDown(() => source.dispose());

  group('offered', () {
    test(
      'sebelum Plus dijual: tidak ada tawaran dan RevenueCat tidak ditanya',
      () async {
        config.current = EntitlementLimits.defaults;
        expect(purchases.isSelling, isFalse);
        expect(await purchases.offered(), OfferedPlans.none);
        expect(gateway.asked, isEmpty);
      },
    );

    test(
      'harga biasa: bulanan lebih dulu, tanpa akun pun boleh (P-9)',
      () async {
        final offered = await purchases.offered();
        expect(offered.offering, OfferingId.standard);
        expect(offered.options.map((o) => o.kind), [
          PlusPlanKind.monthly,
          PlusPlanKind.yearly,
        ]);
        expect(offered.options.last.priceText, 'Rp179.000');
      },
    );

    test('jendela Pendiri: offering founder', () async {
      config.current = limits({
        'plus_launch_at': '2026-12-01',
        'founder_until': '2027-03-01T23:59:00',
      });
      final offered = await purchases.offered();
      expect(offered.offering, OfferingId.founder);
      expect(offered.deadline, DateTime(2027, 3, 1, 23, 59));
    });

    test('Harga Pendiri membawa harga tahunan biasa untuk dicoret', () async {
      config.current = limits({
        'plus_launch_at': '2026-12-01',
        'founder_until': '2027-03-01T23:59:00',
      });
      final founder = (await purchases.offered()).options.singleWhere(
        (o) => o.kind == PlusPlanKind.yearlyFounder,
      );
      expect(founder.regularPriceText, 'Rp179.000');
    });

    test(
      '48 jam sesudah uji coba akun yang masuk: offering post_trial',
      () async {
        uid = 'u1';
        await trials.save(
          TrialRecord(
            uid: 'u1',
            start: DateTime(2026, 12),
            endsOn: DateTime(2026, 12, 9),
          ),
        );
        final offered = await purchases.offered();
        expect(offered.offering, OfferingId.postTrial);
        // Hari terakhir uji coba 9 Des, jadi 10 Des 00.00 + 48 jam.
        expect(offered.deadline, DateTime(2026, 12, 12));
        now = DateTime(2026, 12, 12);
        final later = await purchases.offered();
        expect(later.offering, OfferingId.standard);
        expect(later.deadline, isNull);
      },
    );

    test(
      'offering khusus kosong di RevenueCat jatuh ke harga biasa; semuanya kosong = tidak ada',
      () async {
        config.current = limits({
          'plus_launch_at': '2026-12-01',
          'founder_until': '2027-03-01T23:59:00',
        });
        gateway.offerings.remove('founder');
        expect((await purchases.offered()).offering, OfferingId.standard);
        gateway.offerings.clear();
        expect(await purchases.offered(), OfferedPlans.none);
      },
    );

    test('RevenueCat gagal (luring): tidak melempar', () async {
      gateway.throwOptions = true;
      expect(await purchases.offered(), OfferedPlans.none);
    });
  });

  group('buy', () {
    final option = _opt(PlusPlanKind.yearly, 'Rp179.000');

    test('berhasil: hak baru langsung masuk cache', () async {
      gateway.snapshot = PlusSnapshot(
        isActive: true,
        expiration: DateTime(2027, 12, 10),
      );
      expect(await purchases.buy(option), isA<BuyDone>());
      expect(
        (await cache.load()).getOrElse((_) => null)?.until,
        DateTime(2027, 12, 10),
      );
    });

    test('dibatalkan atau gagal: tidak mengubah cache', () async {
      gateway.result = const BuyCancelled();
      expect(await purchases.buy(option), isA<BuyCancelled>());
      gateway.result = const BuyFailed(PurchaseFailure.network);
      final failed = await purchases.buy(option);
      expect((failed as BuyFailed).reason, PurchaseFailure.network);
      expect((await cache.load()).getOrElse((_) => null), isNull);
    });

    test('SDK melempar: BuyFailed(other), tidak melempar', () async {
      gateway.throwPurchase = true;
      expect(
        ((await purchases.buy(option)) as BuyFailed).reason,
        PurchaseFailure.other,
      );
    });

    test('sebelum Plus dijual: ditolak tanpa menyentuh SDK', () async {
      config.current = EntitlementLimits.defaults;
      expect(await purchases.buy(option), isA<BuyFailed>());
    });
  });

  test('pulihkan pembelian tersedia juga sebelum dijual', () async {
    config.current = EntitlementLimits.defaults;
    gateway.snapshot = const PlusSnapshot(isActive: true, isPromotional: true);
    await purchases.restore();
    expect(gateway.calls, ['restore']);
    expect(
      (await cache.load()).getOrElse((_) => null)?.source,
      PlanSource.promotional,
    );
  });

  test('purchaseResultOfCode: batal bukan galat; jaringan, toko, lainnya', () {
    expect(
      purchaseResultOfCode(PurchasesErrorCode.purchaseCancelledError),
      isA<BuyCancelled>(),
    );
    expect(
      purchaseResultOfCode(PurchasesErrorCode.paymentPendingError),
      isA<BuyPending>(),
    );
    expect(
      (purchaseResultOfCode(PurchasesErrorCode.networkError) as BuyFailed)
          .reason,
      PurchaseFailure.network,
    );
    expect(
      (purchaseResultOfCode(PurchasesErrorCode.storeProblemError) as BuyFailed)
          .reason,
      PurchaseFailure.billing,
    );
    expect(
      (purchaseResultOfCode(PurchasesErrorCode.unknownError) as BuyFailed)
          .reason,
      PurchaseFailure.other,
    );
  });
}
