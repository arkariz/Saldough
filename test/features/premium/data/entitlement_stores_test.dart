import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/premium/data/entitlement_cache_store.dart';
import 'package:saldough/features/premium/data/quota_store.dart';
import 'package:saldough/features/premium/data/trial_store.dart';

T _right<T>(Either<Object, T> result) => result.getOrElse((f) => throw StateError('Left: $f'));

/// Penyimpanan hak Plus (ADR-041 §3.3, §3.4, §3.7).
void main() {
  late InMemoryKeyValueStorage storage;

  setUp(() => storage = InMemoryKeyValueStorage());

  group('TrialStore', () {
    late TrialStore store;
    final record = TrialRecord(uid: 'u1', start: DateTime(2026, 12, 2), endsOn: DateTime(2026, 12, 24));

    setUp(() => store = TrialStore(storage: storage));

    test('kosong: tanpa uji coba dan tanpa firstSeen', () async {
      expect(_right(await store.recordFor('u1')), isNull);
      expect(_right(await store.firstSeen('u1')), isNull);
    });

    test('uji coba disimpan sekali per akun dan tidak pernah ditimpa', () async {
      expect(_right(await store.save(record)), record);
      final later = TrialRecord(uid: 'u1', start: DateTime(2027), endsOn: DateTime(2027, 1, 24));
      expect(_right(await store.save(later)), record, reason: 'yang sudah ada berlaku');
      expect(_right(await TrialStore(storage: storage).recordFor('u1')), record);
    });

    test('akun lain punya rekaman sendiri', () async {
      await store.save(record);
      expect(_right(await store.recordFor('u2')), isNull);
      final other = TrialRecord(uid: 'u2', start: DateTime(2027), endsOn: DateTime(2027, 1, 31));
      await store.save(other);
      expect(_right(await store.recordFor('u1')), record);
      expect(_right(await store.recordFor('u2')), other);
    });

    test('hadiah: belum tampil, ditandai per akun; reanchor hanya sebelum ditampilkan', () async {
      await store.save(record);
      expect(_right(await store.giftSeen('u1')), isFalse);
      final moved = _right(await store.reanchor('u1', DateTime(2027, 1, 9)));
      expect(moved?.endsOn, DateTime(2027, 1, 9));
      expect(_right(await store.recordFor('u1'))?.endsOn, DateTime(2027, 1, 9));
      await store.markGiftSeen('u1');
      expect(_right(await store.giftSeen('u1')), isTrue);
      expect(_right(await store.giftSeen('u2')), isFalse);
      final kept = _right(await store.reanchor('u1', DateTime(2027, 3)));
      expect(kept?.endsOn, DateTime(2027, 1, 9), reason: 'sesudah hadiah tampil tanggal tidak bergeser');
      expect(_right(await store.reanchor('u2', DateTime(2027, 3))), isNull);
    });

    test('firstSeen ditulis sekali, jam dibuang, dan tidak menghapus uji coba', () async {
      await store.save(record);
      expect(_right(await store.markFirstSeen('u1', DateTime(2026, 12, 14, 21))), DateTime(2026, 12, 14));
      expect(_right(await store.markFirstSeen('u1', DateTime(2026, 12, 20))), DateTime(2026, 12, 14));
      expect(_right(await store.recordFor('u1')), record);
    });

    test('dokumen rusak: baca gagal (Left), tulis menimpanya', () async {
      await storage.write(trialStorageKey.value, '{"schemaVersion":1,"accounts":"x"}');
      expect((await store.recordFor('u1')).isLeft(), isTrue);
      expect(_right(await store.save(record)), record);
      expect(_right(await store.recordFor('u1')), record);
    });
  });

  group('EntitlementCacheStore', () {
    late EntitlementCacheStore store;

    setUp(() => store = EntitlementCacheStore(storage: storage));

    test('bolak-balik semua field, waktu setempat', () async {
      final cached = CachedPlus(
        source: PlanSource.purchase,
        until: DateTime(2027, 1, 10, 12),
        inGrace: true,
        onHoldSince: DateTime(2027, 1, 12, 8),
        lastVerifiedAt: DateTime(2027, 1, 9, 7, 30),
      );
      await store.save(cached);
      expect(_right(await EntitlementCacheStore(storage: storage).load()), cached);
    });

    test('hak promosi tanpa tanggal berakhir', () async {
      final promo = CachedPlus(source: PlanSource.promotional, lastVerifiedAt: DateTime(2026, 12));
      await store.save(promo);
      expect(_right(await store.load()), promo);
    });

    test('pengganti uji dan pra-peluncuran tidak pernah masuk cache', () async {
      for (final source in [PlanSource.override, PlanSource.prelaunch]) {
        final result = await store.save(CachedPlus(source: source, lastVerifiedAt: DateTime(2026)));
        expect(result.isLeft(), isTrue, reason: '$source');
      }
      expect(_right(await store.load()), isNull);
    });

    test('clear menghapus', () async {
      await store.save(CachedPlus(source: PlanSource.purchase, lastVerifiedAt: DateTime(2026)));
      await store.clear();
      expect(_right(await store.load()), isNull);
    });

    test('dokumen rusak: Left, tidak melempar', () async {
      await storage.write(entitlementCacheStorageKey.value, '{"schemaVersion":1,"source":"override"}');
      expect((await store.load()).isLeft(), isTrue);
    });
  });

  group('QuotaStore', () {
    late QuotaStore store;
    final nov25 = DateTime(2026, 11, 25);
    final dec25 = DateTime(2026, 12, 25);

    setUp(() => store = QuotaStore(storage: storage));

    test('menambah per fitur dan per ember', () async {
      expect(_right(await store.add(QuotaScope.freePeriod, nov25, PlusFeature.smartInterpretation, 1)), 1);
      expect(_right(await store.add(QuotaScope.freePeriod, nov25, PlusFeature.smartInterpretation, 1)), 2);
      expect(_right(await store.add(QuotaScope.freePeriod, nov25, PlusFeature.ask, 1)), 1);
      expect(_right(await store.used(QuotaScope.freePeriod, nov25, PlusFeature.smartInterpretation)), 2);
      expect(_right(await store.used(QuotaScope.freePeriod, DateTime(2026, 11, 25, 18), PlusFeature.ask)), 1);
    });

    test('periode baru mulai dari nol dan mengganti ember lama', () async {
      await store.add(QuotaScope.freePeriod, nov25, PlusFeature.smartInterpretation, 30);
      expect(_right(await store.used(QuotaScope.freePeriod, dec25, PlusFeature.smartInterpretation)), 0);
      expect(_right(await store.add(QuotaScope.freePeriod, dec25, PlusFeature.smartInterpretation, 1)), 1);
      expect(_right(await store.used(QuotaScope.freePeriod, nov25, PlusFeature.smartInterpretation)), 0);
    });

    test('satuan Gratis dan batas wajar Plus terpisah', () async {
      await store.add(QuotaScope.freePeriod, nov25, PlusFeature.smartInterpretation, 5);
      await store.add(QuotaScope.plusMonth, DateTime(2026, 12), PlusFeature.smartInterpretation, 2);
      expect(_right(await store.used(QuotaScope.freePeriod, nov25, PlusFeature.smartInterpretation)), 5);
      expect(_right(await store.used(QuotaScope.plusMonth, DateTime(2026, 12), PlusFeature.smartInterpretation)), 2);
    });

    test('refund (delta negatif) tidak pernah di bawah nol', () async {
      await store.add(QuotaScope.freePeriod, nov25, PlusFeature.ask, 1);
      expect(_right(await store.add(QuotaScope.freePeriod, nov25, PlusFeature.ask, -1)), 0);
      expect(_right(await store.add(QuotaScope.freePeriod, nov25, PlusFeature.ask, -1)), 0);
    });

    test('dokumen rusak: baca Left, tulis menimpanya', () async {
      await storage.write(quotaStorageKey.value, 'bukan json');
      expect((await store.used(QuotaScope.freePeriod, nov25, PlusFeature.ask)).isLeft(), isTrue);
      expect(_right(await store.add(QuotaScope.freePeriod, nov25, PlusFeature.ask, 1)), 1);
    });
  });
}
