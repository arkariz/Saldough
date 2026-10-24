import 'package:api_storage/api_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/app/data_portability/app_backup_registry.dart';
import 'package:saldough/features/data_portability/data/backup_scope.dart';
import 'package:saldough/features/data_portability/data/restore_engine.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';

import '../../helpers/backup_docs.dart';
import '../../helpers/backup_matchers.dart';
import '../../helpers/faulty_storage.dart';

/// Penggantian data atomik (ADR-040 §3.4, R-4, R-5): jurnal tulis-dulu dengan
/// roll-forward.
void main() {
  late InMemoryKeyValueStorage live;
  late InMemoryKeyValueStorage staging;
  var clock = DateTime(2026, 10, 22, 9);

  // Data lama: dua bulan, dompet "BCA". Data baru: satu bulan lain, dompet
  // "Mandiri", jadi kunci lama (`transaction_2026-08`) harus ikut terhapus.
  final oldDocs = sampleDocs(months: ['2026-08', '2026-10']);
  final newDocs = sampleDocs(wallet: 'Mandiri', months: ['2026-10', '2026-11'], amount: 777);
  const deviceKeys = {
    'settings_language': '{"schemaVersion":1,"code":"en"}',
    'tutorial_progress': '{"schemaVersion":3}',
    'settings_hideAmounts': '{"schemaVersion":1,"hidden":true}',
    // Hak Plus (ADR-041 §3.9): pemulihan tidak boleh memberi, mereset, atau
    // menghapus hak.
    'entitlement_trial': '{"schemaVersion":1,"accounts":{"u1":{"start":"2026-12-02","endsOn":"2026-12-24"}}}',
    'entitlement_cache': '{"schemaVersion":1,"source":"purchase","inGrace":false,"lastVerifiedAt":"2026-12-01T00:00:00.000Z"}',
    'entitlement_quota': '{"schemaVersion":1,"scopes":{}}',
  };

  RestoreEngine engine({KeyValueStorage? liveOverride, KeyValueStorage? stagingOverride}) => RestoreEngine(
    live: liveOverride ?? live,
    staging: stagingOverride ?? staging,
    registry: appBackupRegistry,
    now: () => clock,
  );

  Future<void> seed(KeyValueStorage storage, Map<String, String> docs) async {
    for (final e in docs.entries) {
      await storage.write(e.key, e.value);
    }
  }

  Future<Map<String, String>> scope() => BackupScope.collect(live, appBackupRegistry);

  Future<void> expectDeviceKeysUntouched() async {
    for (final e in deviceKeys.entries) {
      expect(await live.read(e.key), e.value, reason: '${e.key} milik perangkat tidak boleh berubah (R-9)');
    }
  }

  setUp(() async {
    live = InMemoryKeyValueStorage();
    staging = InMemoryKeyValueStorage();
    clock = DateTime(2026, 10, 22, 9);
    await seed(live, oldDocs);
    await seed(live, deviceKeys);
  });

  group('alur normal', () {
    test('stage tidak menyentuh data hidup; recover lalu finalize menerapkan data baru', () async {
      final e = engine();
      await e.stage(incoming: newDocs, kind: RestoreKind.account, backupCreatedAt: DateTime(2026, 10, 12));
      expect(await scope(), oldDocs, reason: 'sebelum recover data lama utuh');

      expect(await e.recover(), RecoveryOutcome.needsFinalize);
      expect(await scope(), newDocs);
      await expectDeviceKeysUntouched();

      var recomputed = 0;
      final report = await e.finalize(() async => recomputed++);
      expect(recomputed, 1);
      expect(report.kind, RestoreKind.account);
      expect(report.backupCreatedAt, DateTime(2026, 10, 12));
      expect(await e.recover(), RecoveryOutcome.none);
    });

    test('kunci lama yang tidak ada di cadangan dihapus, bukan dibiarkan bercampur', () async {
      final e = engine();
      await e.stage(incoming: newDocs, kind: RestoreKind.account);
      await e.recover();
      expect(await live.contains('transaction_2026-08'), isFalse);
      expect(await live.contains('transaction_2026-11'), isTrue);
    });

    test('cadangan pengaman berisi data lama dan berlaku 30 hari', () async {
      final e = engine();
      expect(await e.safetyCopy(), isNull);
      await e.stage(incoming: newDocs, kind: RestoreKind.account);
      expect(await e.safetyCopy(), isNull, reason: 'belum berlaku selama pemulihan berjalan');
      await e.recover();
      await e.finalize(() async {});

      final safety = await e.safetyCopy();
      expect(safety!.createdAt, DateTime(2026, 10, 22, 9));
      expect(safety.expiresAt, DateTime(2026, 11, 21, 9));
    });

    test('Kembalikan: data sebelum pemulihan kembali persis, dan menghasilkan cadangan pengaman baru', () async {
      final e = engine();
      await e.stage(incoming: newDocs, kind: RestoreKind.account);
      await e.recover();
      await e.finalize(() async {});

      expect(await e.stageUndo(), isTrue);
      await e.recover();
      await e.finalize(() async {});
      expect(await scope(), oldDocs);
      await expectDeviceKeysUntouched();

      // Mengembalikan menyimpan data saat itu (yang baru) sebagai pengaman baru.
      expect(await e.stageUndo(), isTrue);
      await e.recover();
      await e.finalize(() async {});
      expect(await scope(), newDocs);
    });

    test('Kembalikan tanpa cadangan pengaman: tidak melakukan apa-apa', () async {
      expect(await engine().stageUndo(), isFalse);
      expect(await scope(), oldDocs);
    });

    test('cadangan pengaman kedaluwarsa dibuang saat bootstrap dan tidak bisa dikembalikan', () async {
      final e = engine();
      await e.stage(incoming: newDocs, kind: RestoreKind.account);
      await e.recover();
      await e.finalize(() async {});

      clock = clock.add(const Duration(days: 31));
      expect(await e.safetyCopy(), isNull);
      expect(await e.stageUndo(), isFalse);
      expect(await e.recover(), RecoveryOutcome.none);
      expect(await staging.contains('meta'), isFalse);
    });

    test('pemulihan kedua menimpa cadangan pengaman dan membersihkan yang lama', () async {
      final e = engine();
      await e.stage(incoming: newDocs, kind: RestoreKind.account);
      await e.recover();
      await e.finalize(() async {});
      final firstMeta = await staging.read('meta');

      clock = clock.add(const Duration(days: 1));
      await e.stage(incoming: oldDocs, kind: RestoreKind.account);
      await e.recover();
      await e.finalize(() async {});
      expect(await staging.read('meta'), isNot(firstMeta));
      final safety = await e.safetyCopy();
      expect(safety!.createdAt, DateTime(2026, 10, 23, 9));
    });
  });

  group('onboarding (belum ada data)', () {
    test('tanpa cadangan pengaman, kunci seed yang tidak ada di cadangan tetap dibersihkan', () async {
      await live.remove('transaction_2026-08');
      final e = engine();
      // Bootstrap sudah mengisi kategori bawaan; cadangan membawa miliknya sendiri.
      await e.stage(incoming: newDocs, kind: RestoreKind.onboarding);
      await e.recover();
      await e.finalize(() async {});
      expect(await scope(), newDocs);
      expect(await e.safetyCopy(), isNull);
    });
  });

  group('penolakan saat menyiapkan', () {
    test('penyimpanan penuh: BackupException space, data hidup dan jurnal bersih', () async {
      final plan = FaultPlan(failAt: 3, permanent: false);
      final e = engine(stagingOverride: FaultyStorage(staging, plan));
      await expectLater(
        e.stage(incoming: newDocs, kind: RestoreKind.account),
        throwsBackup(BackupFailureCodes.space),
      );
      expect(await scope(), oldDocs);
      expect(await staging.contains('journal'), isFalse, reason: 'dibersihkan sehingga tidak ada pemulihan tertunda');
      expect(await engine().recover(), RecoveryOutcome.none);
    });

    test('tidak boleh menyiapkan pemulihan kedua selama jurnal masih ada', () async {
      final e = engine();
      await e.stage(incoming: newDocs, kind: RestoreKind.account);
      expect(() => e.stage(incoming: oldDocs, kind: RestoreKind.account), throwsStateError);
    });
  });

  group('gangguan di tengah (R-4): data lama utuh atau data cadangan utuh, tidak pernah campuran', () {
    // Menjalankan stage → recover dengan galat pada operasi ke-N, lalu
    // "membuka ulang aplikasi" dengan penyimpanan yang sehat. Diulang untuk
    // setiap N sampai tidak ada operasi yang tersisa untuk digagalkan.
    Future<void> sweep({required bool permanent, required bool undo}) async {
      var sawOld = false;
      var sawNew = false;
      for (var n = 0; ; n++) {
        live = InMemoryKeyValueStorage();
        staging = InMemoryKeyValueStorage();
        await seed(live, oldDocs);
        await seed(live, deviceKeys);

        if (undo) {
          // Siapkan cadangan pengaman berisi data lama; data hidup kini baru.
          final setup = engine();
          await setup.stage(incoming: newDocs, kind: RestoreKind.account);
          await setup.recover();
          await setup.finalize(() async {});
        }
        final expectedAfter = undo ? oldDocs : newDocs;
        final expectedBefore = undo ? newDocs : oldDocs;

        final plan = FaultPlan(failAt: n, permanent: permanent);
        final faulty = engine(liveOverride: FaultyStorage(live, plan), stagingOverride: FaultyStorage(staging, plan));
        try {
          if (undo) {
            await faulty.stageUndo();
          } else {
            await faulty.stage(incoming: newDocs, kind: RestoreKind.account);
          }
          await faulty.recover();
        } on Object {
          // proses "mati" di sini
        }

        // Aplikasi dibuka lagi.
        final reopened = engine();
        final outcome = await reopened.recover();
        if (outcome == RecoveryOutcome.needsFinalize) await reopened.finalize(() async {});

        final now = await scope();
        final isOld = _same(now, expectedBefore);
        final isNew = _same(now, expectedAfter);
        expect(isOld || isNew, isTrue, reason: 'operasi $n (permanent=$permanent): data campuran');
        await expectDeviceKeysUntouched();
        // Sesudah dibuka ulang tidak boleh ada pemulihan tertunda.
        expect(await reopened.recover(), RecoveryOutcome.none, reason: 'operasi $n');
        sawOld = sawOld || isOld;
        sawNew = sawNew || isNew;

        if (!plan.triggered) {
          expect(isNew, isTrue, reason: 'tanpa galat hasilnya data baru');
          break;
        }
        expect(n, lessThan(500), reason: 'sapuan tidak berhenti');
      }
      expect(sawOld, isTrue, reason: 'ada galat yang menghasilkan data lama (sebelum applying)');
      expect(sawNew, isTrue, reason: 'ada galat yang menghasilkan data cadangan (roll-forward)');
    }

    test('galat di setiap operasi, proses mati (semua operasi sesudahnya gagal)', () async {
      await sweep(permanent: true, undo: false);
    });

    test('galat tunggal di setiap operasi, proses terus berjalan', () async {
      await sweep(permanent: false, undo: false);
    });

    test('Kembalikan: galat di setiap operasi', () async {
      await sweep(permanent: true, undo: true);
    });

    test('terputus saat finalisasi: diulang saat dibuka lagi, saldo dihitung ulang sekali lagi', () async {
      final e = engine();
      await e.stage(incoming: newDocs, kind: RestoreKind.account);
      await e.recover();
      var recomputed = 0;
      await expectLater(
        e.finalize(() async {
          recomputed++;
          throw StateError('mati saat menghitung ulang saldo');
        }),
        throwsStateError,
      );

      final reopened = engine();
      expect(await reopened.recover(), RecoveryOutcome.needsFinalize);
      await reopened.finalize(() async => recomputed++);
      expect(recomputed, 2);
      expect(await scope(), newDocs);
      expect(await reopened.recover(), RecoveryOutcome.none);
    });
  });
}

bool _same(Map<String, String> a, Map<String, String> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
