import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';

/// Keadaan paket dari sumbernya (ADR-041 §3.2, §3.3, §3.10, §3.13).
void main() {
  final now = DateTime(2026, 12, 10, 9);
  final launched = DateTime(2026, 12);
  final trial = TrialRecord(
    uid: 'u1',
    start: DateTime(2026, 12, 2),
    endsOn: DateTime(2026, 12, 24),
  );

  PlanState resolve({
    DateTime? at,
    DateTime? launchAt,
    bool prelaunch = false,
    String? uid,
    TrialRecord? trialRecord,
    CachedPlus? cached,
    PlanOverride override = PlanOverride.auto,
  }) => resolvePlan(
    now: at ?? now,
    launchAt: prelaunch ? null : (launchAt ?? launched),
    signedInUid: uid,
    trial: trialRecord,
    cached: cached,
    override: override,
  );

  group('pra-peluncuran (§3.13 butir 1)', () {
    test('masuk akun = Plus tanpa batas waktu; tanpa akun = Gratis', () {
      expect(
        resolve(prelaunch: true, uid: 'u1'),
        const PlusPlan(source: PlanSource.prelaunch),
      );
      expect(resolve(prelaunch: true), const FreePlan());
    });

    test('tanggal peluncuran yang belum tiba tetap pra-peluncuran', () {
      expect(
        resolve(launchAt: DateTime(2027), uid: 'u1'),
        const PlusPlan(source: PlanSource.prelaunch),
      );
      expect(resolve(launchAt: DateTime(2027)), const FreePlan());
    });

    test('uji coba tidak berlaku selama pra-peluncuran', () {
      expect(resolve(prelaunch: true, trialRecord: trial), const FreePlan());
    });
  });

  group('uji coba (§3.4)', () {
    test('milik akun yang sedang masuk, sampai hari terakhirnya', () {
      expect(
        resolve(uid: 'u1', trialRecord: trial),
        TrialPlan(endsOn: DateTime(2026, 12, 24)),
      );
      expect(
        resolve(
          uid: 'u1',
          trialRecord: trial,
          at: DateTime(2026, 12, 24, 23, 59),
        ),
        isA<TrialPlan>(),
      );
      expect(
        resolve(uid: 'u1', trialRecord: trial, at: DateTime(2026, 12, 25)),
        const FreePlan(),
      );
    });

    test('keluar akun atau akun lain: Gratis', () {
      expect(resolve(trialRecord: trial), const FreePlan());
      expect(resolve(uid: 'u2', trialRecord: trial), const FreePlan());
    });
  });

  group('hak RevenueCat dan tenggang luring (§3.3)', () {
    final until = DateTime(2026, 12, 10, 12);

    CachedPlus cache({
      DateTime? verified,
      bool inGrace = false,
      DateTime? onHold,
      DateTime? untilAt,
    }) => CachedPlus(
      source: PlanSource.purchase,
      until: untilAt ?? until,
      lastVerifiedAt: verified ?? DateTime(2026, 12, 9),
      inGrace: inGrace,
      onHoldSince: onHold,
    );

    test('berlaku sampai until; Plus mengalahkan uji coba', () {
      expect(
        resolve(uid: 'u1', trialRecord: trial, cached: cache()),
        PlusPlan(source: PlanSource.purchase, until: until),
      );
    });

    test(
      'tanpa koneksi: tetap Plus tepat 3 hari sesudah until, lalu Gratis',
      () {
        expect(
          resolve(cached: cache(), at: until.add(const Duration(days: 3))),
          isA<PlusPlan>(),
        );
        expect(
          resolve(
            cached: cache(),
            at: until.add(const Duration(days: 3, seconds: 1)),
          ),
          const FreePlan(),
        );
      },
    );

    test(
      'sudah diverifikasi sesudah until tanpa perpanjangan: langsung berakhir',
      () {
        expect(
          resolve(
            cached: cache(verified: until.add(const Duration(hours: 1))),
            at: until.add(const Duration(hours: 2)),
          ),
          const FreePlan(),
        );
      },
    );

    test('masa tenggang Play tetap Plus', () {
      expect(
        resolve(cached: cache(inGrace: true)),
        PlusPlan(source: PlanSource.purchase, until: until, inGrace: true),
      );
    });

    test(
      'ditahan: perilaku Gratis dengan keadaan sendiri; uji coba yang masih berjalan menang',
      () {
        final held = cache(onHold: DateTime(2026, 12, 5));
        expect(resolve(cached: held), OnHoldPlan(since: DateTime(2026, 12, 5)));
        expect(resolve(cached: held).isPlus, isFalse);
        expect(
          resolve(uid: 'u1', trialRecord: trial, cached: held),
          isA<TrialPlan>(),
        );
      },
    );

    test('hak promosi tanpa tanggal berakhir berlaku terus', () {
      final promo = CachedPlus(
        source: PlanSource.promotional,
        lastVerifiedAt: DateTime(2026),
      );
      expect(
        resolve(cached: promo, at: DateTime(2030)),
        const PlusPlan(source: PlanSource.promotional),
      );
    });
  });

  group('pengganti paket (§3.10)', () {
    test('plus, free, trial mengalahkan semua sumber', () {
      expect(
        resolve(override: PlanOverride.plus),
        const PlusPlan(source: PlanSource.override),
      );
      expect(
        resolve(override: PlanOverride.free, uid: 'u1', prelaunch: true),
        const FreePlan(),
      );
      expect(
        resolve(override: PlanOverride.trial),
        TrialPlan(endsOn: DateTime(2026, 12, 11)),
      );
    });
  });

  test('isPlus hanya untuk uji coba dan Plus', () {
    expect(const FreePlan().isPlus, isFalse);
    expect(TrialPlan(endsOn: DateTime(2026)).isPlus, isTrue);
    expect(const PlusPlan(source: PlanSource.purchase).isPlus, isTrue);
    expect(OnHoldPlan(since: DateTime(2026)).isPlus, isFalse);
  });
}
