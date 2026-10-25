import 'dart:async';

import 'package:api_storage/api_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/financial_month/financial_period.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/premium/data/entitlement_cache_store.dart';
import 'package:saldough/features/premium/data/local_entitlements.dart';
import 'package:saldough/features/premium/data/quota_store.dart';
import 'package:saldough/features/premium/data/trial_store.dart';

/// Penyimpanan yang selalu gagal (baca dan tulis).
final class _BrokenStorage implements KeyValueStorage {
  Never _fail() => throw StateError('penyimpanan rusak');

  @override
  Future<String?> read(String key) async => _fail();

  @override
  Future<void> write(String key, String value) async => _fail();

  @override
  Future<void> remove(String key) async => _fail();

  @override
  Future<bool> contains(String key) async => _fail();

  @override
  Future<void> clear() async => _fail();
}

final class _Config implements EntitlementConfig {
  final _changes = StreamController<EntitlementLimits>.broadcast();

  @override
  EntitlementLimits current = EntitlementLimits.defaults;

  int refreshed = 0;

  void set(EntitlementLimits next) {
    current = next;
    _changes.add(next);
  }

  @override
  Stream<EntitlementLimits> get changes => _changes.stream;

  @override
  Future<void> refresh() async => refreshed++;
}

/// Hak dari sumber lokal (ADR-041 §3.3, §3.4, §3.7, §3.13).
void main() {
  late InMemoryKeyValueStorage storage;
  late _Config config;
  late DateTime now;
  late LocalEntitlements entitlements;
  final from25 = FinancialMonthSchedule.single(
    const FinancialMonthStart.day(25),
  );
  final launched = EntitlementLimits.fromValues(const {
    'plus_launch_at': '2026-11-01',
  });

  LocalEntitlements build({
    PlanOverride override = PlanOverride.auto,
    Future<void> Function(String uid)? verify,
    Duration verifyTimeout = const Duration(seconds: 4),
  }) =>
      LocalEntitlements(
        config: config,
        trials: TrialStore(storage: storage),
        cache: EntitlementCacheStore(storage: storage),
        quotas: QuotaStore(storage: storage),
        schedule: () => from25,
        override: () => override,
        now: () => now,
        verifyPurchase: verify,
        verifyTimeout: verifyTimeout,
      );

  setUp(() {
    storage = InMemoryKeyValueStorage();
    config = _Config();
    now = DateTime(2026, 11, 3, 9);
    entitlements = build();
  });

  tearDown(() => entitlements.dispose());

  group('pra-peluncuran (§3.13)', () {
    test(
      'tanpa akun Gratis; masuk akun Plus; keluar kembali Gratis, dengan pancaran',
      () async {
        expect(entitlements.current, const FreePlan());
        final emitted = <PlanState>[];
        final sub = entitlements.changes.listen(emitted.add);
        await entitlements.setAccount(const EntitlementAccount(uid: 'u1'));
        expect(
          entitlements.current,
          const PlusPlan(source: PlanSource.prelaunch),
        );
        expect(entitlements.can(PlusFeature.recurringAutomation), isTrue);
        await entitlements.setAccount(null);
        expect(entitlements.current, const FreePlan());
        await Future<void>.delayed(Duration.zero);
        expect(emitted, [
          const PlusPlan(source: PlanSource.prelaunch),
          const FreePlan(),
        ]);
        await sub.cancel();
      },
    );

    test('uji coba tidak dimulai selama pra-peluncuran', () async {
      await entitlements.setAccount(
        EntitlementAccount(uid: 'u1', createdAt: DateTime(2026, 11, 2)),
      );
      expect(
        (await TrialStore(
          storage: storage,
        ).recordFor('u1')).getOrElse((_) => null),
        isNull,
      );
    });
  });

  group('sesudah peluncuran: uji coba saat masuk akun (§3.4)', () {
    setUp(() => config.current = launched);

    test(
      'akun baru: mulai dari hari pembuatan akun, berakhir di akhir periode',
      () async {
        await entitlements.setAccount(
          EntitlementAccount(uid: 'u1', createdAt: DateTime(2026, 11, 2, 20)),
        );
        expect(entitlements.current, TrialPlan(endsOn: DateTime(2026, 11, 24)));
        final record = (await TrialStore(
          storage: storage,
        ).recordFor('u1')).getOrElse((_) => null);
        expect(record?.start, DateTime(2026, 11, 2));
      },
    );

    test('akun lama: mulai dari hari pertama masuk di perangkat ini', () async {
      now = DateTime(2026, 11, 15, 9);
      await entitlements.setAccount(
        EntitlementAccount(uid: 'u1', createdAt: DateTime(2026, 9, 29)),
      );
      expect(
        entitlements.current,
        TrialPlan(endsOn: DateTime(2026, 12, 24)),
        reason: '15–24 Nov < 14 hari',
      );
    });

    test(
      'uji coba dihitung sekali: masuk ulang tidak memperpanjang; habis = Gratis',
      () async {
        await entitlements.setAccount(
          EntitlementAccount(uid: 'u1', createdAt: DateTime(2026, 11, 2)),
        );
        await entitlements.setAccount(null);
        now = DateTime(2026, 11, 30);
        final again = build();
        await again.setAccount(
          EntitlementAccount(uid: 'u1', createdAt: DateTime(2026, 11, 2)),
        );
        expect(again.current, const FreePlan());
        await again.dispose();
      },
    );

    group('pembeli di sesi baru', () {
      final account = EntitlementAccount(uid: 'u1', createdAt: DateTime(2026, 11, 2));

      test('langganan terbaca sebelum uji coba: langsung Plus, tanpa uji coba', () async {
        final emitted = <PlanState>[];
        final fresh = build(
          verify: (uid) async => EntitlementCacheStore(storage: storage).save(
            CachedPlus(source: PlanSource.purchase, until: DateTime(2027, 11), lastVerifiedAt: now),
          ),
        );
        addTearDown(fresh.dispose);
        final sub = fresh.changes.listen(emitted.add);
        await fresh.setAccount(account);
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();
        expect(fresh.current, PlusPlan(source: PlanSource.purchase, until: DateTime(2027, 11)));
        expect(emitted.whereType<TrialPlan>(), isEmpty, reason: 'tidak sempat terlihat sebagai uji coba');
        expect(
          (await TrialStore(storage: storage).recordFor('u1')).getOrElse((_) => null),
          isNull,
          reason: 'uji coba tidak dibuat bagi pembeli',
        );
      });

      test('tanpa langganan: tetap uji coba; pemeriksaan hanya sekali per akun', () async {
        var calls = 0;
        final fresh = build(verify: (uid) async => calls++);
        addTearDown(fresh.dispose);
        await fresh.setAccount(account);
        expect(fresh.current, isA<TrialPlan>());
        await fresh.recompute();
        expect(calls, 1);
      });

      test('pemeriksaan gagal atau melewati batas waktu: lanjut ke uji coba', () async {
        final slow = build(
          verify: (uid) => Completer<void>().future,
          verifyTimeout: const Duration(milliseconds: 20),
        );
        addTearDown(slow.dispose);
        await slow.setAccount(account);
        expect(slow.current, isA<TrialPlan>());
        final broken = build(verify: (uid) async => throw StateError('luring'));
        addTearDown(broken.dispose);
        await broken.setAccount(EntitlementAccount(uid: 'u2', createdAt: DateTime(2026, 11, 2)));
        expect(broken.current, isA<TrialPlan>());
      });
    });

    test('pembeli yang Plus-nya lewat tenggang luring jadi Gratis, bukan uji coba', () async {
      final purchase = CachedPlus(
        source: PlanSource.purchase,
        until: DateTime(2026, 11, 3, 9, 5),
        lastVerifiedAt: DateTime(2026, 11, 3, 9),
      );
      await EntitlementCacheStore(storage: storage).save(purchase);
      final buyer = build(verify: (uid) async {});
      addTearDown(buyer.dispose);
      await buyer.reloadCache();
      await buyer.setAccount(EntitlementAccount(uid: 'u1', createdAt: DateTime(2026, 11, 2)));
      expect(buyer.current, isA<PlusPlan>());
      now = DateTime(2026, 11, 10);
      await buyer.recompute();
      expect(buyer.current, const FreePlan(), reason: 'lewat tenggang 3 hari: Gratis, tidak membuka uji coba');
      final again = build(verify: (uid) async {});
      addTearDown(again.dispose);
      await again.setAccount(EntitlementAccount(uid: 'u1', createdAt: DateTime(2026, 11, 2)));
      expect(again.current, const FreePlan(), reason: 'penanda pembelian bertahan di sesi baru');
    });

    test('pembelian anonim lalu masuk akun: tidak ada uji coba bagi akun itu', () async {
      final anon = build();
      addTearDown(anon.dispose);
      await EntitlementCacheStore(storage: storage).save(
        CachedPlus(source: PlanSource.purchase, until: DateTime(2026, 11, 3, 9, 5), lastVerifiedAt: now),
      );
      await anon.reloadCache();
      now = DateTime(2026, 11, 10);
      await anon.setAccount(EntitlementAccount(uid: 'u9', createdAt: DateTime(2026, 11, 2)));
      expect(anon.current, const FreePlan());
    });

    test('tanpa akun tetap Gratis', () async {
      await entitlements.setAccount(null);
      expect(entitlements.current, const FreePlan());
    });

    test(
      'peluncuran lewat Remote Config saat aplikasi terbuka memulai uji coba yang masuk',
      () async {
        config.current = EntitlementLimits.defaults;
        await entitlements.setAccount(
          EntitlementAccount(uid: 'u1', createdAt: DateTime(2026, 11, 2)),
        );
        expect(
          entitlements.current,
          const PlusPlan(source: PlanSource.prelaunch),
        );
        final next = entitlements.changes.first;
        config.set(launched);
        expect(await next, TrialPlan(endsOn: DateTime(2026, 11, 24)));
      },
    );
  });

  test('cache RevenueCat dihormati (hak promosi)', () async {
    config.current = launched;
    await EntitlementCacheStore(
      storage: storage,
    ).save(CachedPlus(source: PlanSource.promotional, lastVerifiedAt: now));
    await entitlements.reloadCache();
    expect(
      entitlements.current,
      const PlusPlan(source: PlanSource.promotional),
    );
  });

  test('pengganti paket mengalahkan semuanya', () async {
    final forced = build(override: PlanOverride.plus);
    expect(forced.current, const PlusPlan(source: PlanSource.override));
    await forced.dispose();
  });

  group('batas dan jatah (§3.7)', () {
    test('allows: Gratis di bawah batas saja, Plus selalu', () async {
      expect(
        entitlements.allows(PlusFeature.budgetTemplates, count: 0),
        isTrue,
      );
      expect(
        entitlements.allows(PlusFeature.budgetTemplates, count: 1),
        isFalse,
      );
      expect(
        entitlements.allows(PlusFeature.freelanceProjects, count: 1),
        isTrue,
      );
      expect(
        entitlements.allows(PlusFeature.freelanceProjects, count: 2),
        isFalse,
      );
      await entitlements.setAccount(const EntitlementAccount(uid: 'u1'));
      expect(
        entitlements.allows(PlusFeature.budgetTemplates, count: 5),
        isTrue,
      );
    });

    test(
      'jatah Gratis per periode: habis sesudah batas, refund mengembalikan, periode baru reset',
      () async {
        config.current = EntitlementLimits.fromValues(const {'taste_ask': '2'});
        expect(await entitlements.tryUse(PlusFeature.ask), isTrue);
        expect(await entitlements.tryUse(PlusFeature.ask), isTrue);
        expect(await entitlements.tryUse(PlusFeature.ask), isFalse);
        expect((await entitlements.quota(PlusFeature.ask)).remaining, 0);
        await entitlements.refund(PlusFeature.ask);
        expect(await entitlements.tryUse(PlusFeature.ask), isTrue);
        now = DateTime(2026, 11, 25, 8);
        expect(
          await entitlements.quota(PlusFeature.ask),
          const QuotaStatus(used: 0, limit: 2),
        );
      },
    );

    test(
      'Plus: batas wajar bulanan; fitur tanpa batas wajar tidak dihitung',
      () async {
        await entitlements.setAccount(const EntitlementAccount(uid: 'u1'));
        expect(
          await entitlements.quota(PlusFeature.smartInterpretation),
          const QuotaStatus(used: 0, limit: 1000),
        );
        expect(await entitlements.tryUse(PlusFeature.guardian), isTrue);
        expect(
          await entitlements.quota(PlusFeature.guardian),
          QuotaStatus.unlimited,
        );
      },
    );
  });

  test('penyimpanan gagal: tidak melempar, keadaan tetap dihitung', () async {
    final broken = LocalEntitlements(
      config: config,
      trials: TrialStore(storage: _BrokenStorage()),
      cache: EntitlementCacheStore(storage: _BrokenStorage()),
      quotas: QuotaStore(storage: _BrokenStorage()),
      schedule: () => from25,
      now: () => now,
    );
    await broken.setAccount(const EntitlementAccount(uid: 'u1'));
    expect(broken.current, const PlusPlan(source: PlanSource.prelaunch));
    expect(await broken.tryUse(PlusFeature.ask), isTrue);
    await broken.dispose();
  });

  test('refresh mengambil batas terbaru', () async {
    await entitlements.refresh();
    expect(config.refreshed, 1);
  });
}
