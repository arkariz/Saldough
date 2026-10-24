import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/premium/data/entitlement_cache_store.dart';
import 'package:saldough/features/premium/data/plus_snapshot.dart';
import 'package:saldough/features/premium/data/purchases_gateway.dart';
import 'package:saldough/features/premium/data/revenuecat_plan_source.dart';
import 'package:saldough/features/premium/domain/purchase_models.dart';

final class _FakeGateway implements PurchasesGateway {
  final controller = StreamController<PlusSnapshot?>.broadcast();
  final calls = <String>[];
  PlusSnapshot? next;
  bool failNext = false;
  bool failConfigure = false;

  Future<PlusSnapshot?> _answer(String call) async {
    calls.add(call);
    if (failNext) {
      failNext = false;
      throw StateError('luring');
    }
    return next;
  }

  @override
  Future<void> configure() async {
    calls.add('configure');
    if (failConfigure) throw StateError('SDK');
  }

  @override
  Future<PlusSnapshot?> logIn(String uid) => _answer('logIn:$uid');

  @override
  Future<PlusSnapshot?> logOut() => _answer('logOut');

  @override
  Future<PlusSnapshot?> fetch() => _answer('fetch');

  @override
  Future<PlusSnapshot?> restore() => _answer('restore');

  @override
  Stream<PlusSnapshot?> get updates => controller.stream;

  @override
  Future<List<PlanOption>> options(String offeringId) async => const [];

  @override
  Future<({BuyResult result, PlusSnapshot? snapshot})> purchase(PlanOption option) async =>
      (result: const BuyDone(), snapshot: next);
}

EntitlementInfo _info({
  bool active = true,
  Store store = Store.playStore,
  String? expiration = '2027-01-10T05:00:00Z',
  String? billingIssue,
}) => EntitlementInfo(
  plusEntitlementId,
  active,
  true,
  '2026-12-10T05:00:00Z',
  '2026-12-10T05:00:00Z',
  'plus:monthly',
  false,
  store: store,
  expirationDate: expiration,
  billingIssueDetectedAt: billingIssue,
);

T _right<T>(Either<Object, T> result) =>
    result.getOrElse((f) => throw StateError('Left: $f'));

/// Hak dari RevenueCat ke cache (ADR-041 §3.3, §3.5).
void main() {
  group('snapshotOfEntitlement', () {
    test(
      'tanpa entitlement: null',
      () => expect(snapshotOfEntitlement(null), isNull),
    );

    test('pembelian Play aktif dengan tanggal berakhir (waktu setempat)', () {
      final snapshot = snapshotOfEntitlement(_info())!;
      expect(snapshot.isActive, isTrue);
      expect(snapshot.isPromotional, isFalse);
      expect(snapshot.expiration, DateTime.utc(2027, 1, 10, 5).toLocal());
      expect(snapshot.billingIssueSince, isNull);
    });

    test('hak promosi tanpa tanggal berakhir', () {
      final snapshot = snapshotOfEntitlement(
        _info(store: Store.promotional, expiration: null),
      )!;
      expect(snapshot.isPromotional, isTrue);
      expect(snapshot.expiration, isNull);
    });

    test(
      'masalah pembayaran: aktif = tenggang, tidak aktif = ditahan; tanggal rusak diabaikan',
      () {
        final grace = snapshotOfEntitlement(
          _info(billingIssue: '2026-12-20T00:00:00Z'),
        )!;
        expect(grace.inGrace, isTrue);
        expect(grace.onHold, isFalse);
        final held = snapshotOfEntitlement(
          _info(active: false, billingIssue: '2026-12-20T00:00:00Z'),
        )!;
        expect(held.onHold, isTrue);
        expect(held.inGrace, isFalse);
        expect(
          snapshotOfEntitlement(_info(expiration: 'rusak'))!.expiration,
          isNull,
        );
      },
    );
  });

  group('RevenueCatPlanSource', () {
    late _FakeGateway gateway;
    late EntitlementCacheStore cache;
    late RevenueCatPlanSource source;
    late int changed;
    final now = DateTime(2026, 12, 12, 9);

    setUp(() async {
      gateway = _FakeGateway();
      cache = EntitlementCacheStore(storage: InMemoryKeyValueStorage());
      changed = 0;
      source = RevenueCatPlanSource(
        gateway: gateway,
        cache: cache,
        onChanged: () async => changed++,
        now: () => now,
      );
      await source.start();
    });

    tearDown(() async {
      await source.dispose();
      await gateway.controller.close();
    });

    Future<CachedPlus?> cached() async => _right(await cache.load());

    test(
      'pembelian aktif disalin ke cache dengan waktu verifikasi dan memberi tahu',
      () async {
        gateway.next = PlusSnapshot(
          isActive: true,
          expiration: DateTime(2027, 1, 10),
        );
        await source.refresh();
        expect(
          await cached(),
          CachedPlus(
            source: PlanSource.purchase,
            until: DateTime(2027, 1, 10),
            lastVerifiedAt: now,
          ),
        );
        expect(changed, 1);
      },
    );

    test('hak promosi: sumber promotional', () async {
      gateway.next = const PlusSnapshot(isActive: true, isPromotional: true);
      await source.refresh();
      expect((await cached())?.source, PlanSource.promotional);
      expect((await cached())?.until, isNull);
    });

    test('masa tenggang Play: tetap aktif dengan inGrace', () async {
      gateway.next = PlusSnapshot(
        isActive: true,
        expiration: DateTime(2026, 12, 11),
        billingIssueSince: DateTime(2026, 12, 8),
      );
      await source.refresh();
      expect((await cached())?.inGrace, isTrue);
      expect((await cached())?.onHoldSince, isNull);
    });

    test('ditahan: cache membawa onHoldSince', () async {
      gateway.next = PlusSnapshot(
        isActive: false,
        billingIssueSince: DateTime(2026, 12, 8),
      );
      await source.refresh();
      expect((await cached())?.onHoldSince, DateTime(2026, 12, 8));
    });

    test(
      'kedaluwarsa tanpa masalah atau tanpa entitlement: cache dihapus',
      () async {
        gateway.next = PlusSnapshot(
          isActive: true,
          expiration: DateTime(2027, 1, 10),
        );
        await source.refresh();
        gateway.next = const PlusSnapshot(isActive: false);
        await source.refresh();
        expect(await cached(), isNull);

        gateway.next = PlusSnapshot(
          isActive: true,
          expiration: DateTime(2027, 1, 10),
        );
        await source.refresh();
        gateway.next = null;
        await source.refresh();
        expect(await cached(), isNull);
      },
    );

    test(
      'gagal membaca (luring): cache lama dibiarkan, tidak melempar, tidak memberi tahu',
      () async {
        gateway.next = PlusSnapshot(
          isActive: true,
          expiration: DateTime(2027, 1, 10),
        );
        await source.refresh();
        final before = await cached();
        gateway.failNext = true;
        await source.refresh();
        expect(await cached(), before);
        expect(changed, 1);
      },
    );

    test('masuk dan keluar akun mengikat ulang pengguna RevenueCat', () async {
      gateway.next = const PlusSnapshot(isActive: true, isPromotional: true);
      await source.setUser('u1');
      await source.setUser(null);
      expect(gateway.calls, ['configure', 'logIn:u1', 'logOut']);
    });

    test('pembaruan dari SDK (pembelian) langsung disalin', () async {
      gateway.controller.add(
        PlusSnapshot(isActive: true, expiration: DateTime(2027, 2)),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect((await cached())?.until, DateTime(2027, 2));
    });

    test('pulihkan pembelian memakai restore', () async {
      gateway.next = PlusSnapshot(
        isActive: true,
        expiration: DateTime(2027, 1, 10),
      );
      await source.restore();
      expect(gateway.calls.last, 'restore');
      expect(await cached(), isNotNull);
    });

    test(
      'SDK gagal disiapkan: sumber tidak aktif dan semua panggilan diam',
      () async {
        final broken = _FakeGateway()..failConfigure = true;
        final inert = RevenueCatPlanSource(
          gateway: broken,
          cache: cache,
          onChanged: () async => changed++,
          now: () => now,
        );
        await inert.start();
        await inert.setUser('u1');
        await inert.refresh();
        expect(broken.calls, ['configure']);
        expect(await cached(), isNull);
      },
    );
  });
}
