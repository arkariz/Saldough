import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/app/data_portability/app_backup_registry.dart';
import 'package:saldough/features/data_portability/data/backup_codec.dart';
import 'package:saldough/features/data_portability/data/backup_scope.dart';
import 'package:saldough/features/data_portability/data/backup_service.dart';
import 'package:saldough/features/data_portability/data/restore_engine.dart';
import 'package:saldough/features/data_portability/data/restore_service.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/backup_summary.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';

import '../../helpers/backup_docs.dart';

/// Pulihkan (EXPORT_BACKUP §7, ADR-040 §3.4): periksa, bandingkan, siapkan,
/// terapkan.
void main() {
  late InMemoryKeyValueStorage live;
  late InMemoryKeyValueStorage staging;
  var now = DateTime(2026, 10, 22, 9);

  RestoreEngine engine() => RestoreEngine(live: live, staging: staging, registry: appBackupRegistry, now: () => now);

  RestoreService service() => RestoreService(storage: live, engine: engine(), registry: appBackupRegistry);

  Future<void> seed(Map<String, String> docs) async {
    for (final e in docs.entries) {
      await live.write(e.key, e.value);
    }
  }

  Uint8List backupOf(Map<String, String> docs, {DateTime? createdAt, int schema = 1}) => BackupCodec.encode(
    docs: docs,
    createdAt: createdAt ?? DateTime(2026, 10, 12, 9),
    appVersion: '0.8.0',
    appBuild: 14,
    summary: const BackupSummary(transactions: 0, wallets: 0, firstDate: null, currency: null),
  );

  RestoreSession ok(dynamic either) => (either as dynamic).getOrElse((_) => throw StateError('Left')) as RestoreSession;

  setUp(() {
    live = InMemoryKeyValueStorage();
    staging = InMemoryKeyValueStorage();
    now = DateTime(2026, 10, 22, 9);
  });

  group('inspect', () {
    test('pratinjau: ringkasan cadangan dihitung dari dokumen dan dibandingkan dengan data sekarang', () async {
      await seed(sampleDocs(months: ['2026-09', '2026-10'], amount: 5));
      final backup = sampleDocs(months: ['2026-09']);
      final session = ok(await service().inspect(backupOf(backup)));

      expect(session.preview.backup.transactions, 1);
      expect(session.preview.current.transactions, 2);
      expect(session.preview.backupCreatedAt, DateTime(2026, 10, 12, 9));
      expect(session.docs, backup);
      expect(session.preview.source, RestoreKind.account);
    });

    test(
      'cadangan lebih lama: transaksi lebih sedikit, atau transaksi terakhir lebih baru dari tanggal cadangan',
      () async {
        await seed(sampleDocs(months: ['2026-09', '2026-10']));
        final fewer = ok(await service().inspect(backupOf(sampleDocs(months: ['2026-09']))));
        expect(fewer.preview.isOlderThanCurrent, isTrue);

        // Jumlah sama, tetapi transaksi terakhir (3 Okt) lebih baru dari cadangan (1 Okt).
        final sameCount = ok(
          await service().inspect(
            backupOf(sampleDocs(months: ['2026-09', '2026-10']), createdAt: DateTime(2026, 10, 1, 9)),
          ),
        );
        expect(sameCount.preview.isOlderThanCurrent, isTrue);
      },
    );

    test('cadangan lebih baru atau sama: bukan yang lebih lama', () async {
      await seed(sampleDocs(months: ['2026-09']));
      final session = ok(
        await service().inspect(
          backupOf(sampleDocs(months: ['2026-09', '2026-10']), createdAt: DateTime(2026, 10, 20)),
        ),
      );
      expect(session.preview.isOlderThanCurrent, isFalse);
    });

    test('mata uang berbeda disebut (R-7); sama atau belum tersimpan tidak', () async {
      await seed(sampleDocs());
      final usd = sampleDocs()..['settings_currency'] = jsonEncode({'schemaVersion': 1, 'code': 'USD'});
      expect(ok(await service().inspect(backupOf(usd))).preview.newCurrency, 'USD');
      expect(ok(await service().inspect(backupOf(sampleDocs()))).preview.newCurrency, isNull);
    });

    test('draf kotak masuk yang belum ditinjau dihitung karena ikut terganti (R-10)', () async {
      await seed(sampleDocs());
      await live.write(
        'capture_inbox',
        jsonEncode({
          'schemaVersion': 1,
          'items': <Object?>[<String, Object?>{}, <String, Object?>{}, <String, Object?>{}],
        }),
      );
      expect(ok(await service().inspect(backupOf(sampleDocs()))).preview.lostInboxDrafts, 3);
    });

    test('dari onboarding: tidak ada perbandingan "lebih lama" dan tidak ada draf', () async {
      await seed(sampleDocs(months: ['2026-09', '2026-10']));
      await live.write(
        'capture_inbox',
        jsonEncode({
          'items': <Object?>[<String, Object?>{}],
        }),
      );
      final session = ok(
        await service().inspect(backupOf(sampleDocs(months: ['2026-09'])), source: RestoreKind.onboarding),
      );
      expect(session.preview.isOlderThanCurrent, isFalse);
      expect(session.preview.lostInboxDrafts, 0);
    });

    test(
      'berkas rusak, bukan cadangan, versi lebih baru, rujukan tidak utuh: ditolak dan data tidak tersentuh',
      () async {
        await seed(sampleDocs());
        final before = await BackupScope.collect(live, appBackupRegistry);

        Future<dynamic> codeOf(Uint8List bytes) async =>
            (await service().inspect(bytes)).swap().getOrElse((_) => throw StateError('Right')).code;

        expect(await codeOf(Uint8List.fromList(utf8.encode('halo'))), BackupFailureCodes.invalid);
        final newer = sampleDocs()..['fitur_baru_all'] = '{}';
        expect(await codeOf(backupOf(newer)), BackupFailureCodes.newer);
        final broken = sampleDocs()..['wallet_all'] = jsonEncode({'schemaVersion': 1, 'items': <Object?>[]});
        expect(await codeOf(backupOf(broken)), BackupFailureCodes.inconsistent);

        expect(await BackupScope.collect(live, appBackupRegistry), before);
        expect(await staging.contains('journal'), isFalse, reason: 'memeriksa tidak menulis apa pun');
      },
    );
  });

  group('stage → bootstrap → finalize', () {
    test('menyiapkan tidak menyentuh data hidup; recover menerapkan; data sama persis dengan cadangan', () async {
      final old = sampleDocs(wallet: 'Lama', months: ['2026-08', '2026-10']);
      final target = sampleDocs(wallet: 'Baru', months: ['2026-10', '2026-11'], amount: 777);
      await seed(old);
      await live.write('settings_language', '{"schemaVersion":1,"code":"en"}');

      final s = service();
      final session = ok(await s.inspect(backupOf(target)));
      expect((await s.stage(session)).isRight(), isTrue);
      expect(await BackupScope.collect(live, appBackupRegistry), old, reason: 'data hidup belum disentuh');

      // "Boot ulang": jalur pemulihan jurnal.
      final e = engine();
      expect(await e.recover(), RecoveryOutcome.needsFinalize);
      final report = await e.finalize(() async {});
      expect(await BackupScope.collect(live, appBackupRegistry), target);
      expect(await live.read('settings_language'), '{"schemaVersion":1,"code":"en"}');
      expect(report.kind, RestoreKind.account);
      expect(report.restoredKeys, containsAll(['wallet_all', 'transaction_2026-11']));
    });

    test(
      'laporan: izin sistem perlu diberikan lagi bila cadangan memuat pengingat atau Catat dari notifikasi',
      () async {
        final target = sampleDocs()..['settings_recurring_reminders'] = '{"schemaVersion":1,"enabled":true}';
        final s = service();
        await s.stage(ok(await s.inspect(backupOf(target))));
        final e = engine();
        await e.recover();
        expect((await e.finalize(() async {})).mayNeedPermissions, isTrue);

        final plain = sampleDocs();
        await s.stage(ok(await s.inspect(backupOf(plain))));
        await e.recover();
        expect((await e.finalize(() async {})).mayNeedPermissions, isFalse);
      },
    );

    test('Kembalikan: cadangan pengaman berisi data sebelum pemulihan, dan bisa diterapkan kembali', () async {
      final old = sampleDocs(wallet: 'Lama');
      final target = sampleDocs(wallet: 'Baru', amount: 777);
      await seed(old);
      final s = service();
      await s.stage(ok(await s.inspect(backupOf(target))));
      final e = engine();
      await e.recover();
      await e.finalize(() async {});

      final info = (await s.safetyCopy()).getOrElse((_) => throw StateError('Left'));
      expect(info!.createdAt, now);

      final undo = (await s.inspectSafetyCopy()).getOrElse((_) => throw StateError('Left'))!;
      expect(undo.preview.source, RestoreKind.undo);
      expect(undo.preview.isOlderThanCurrent, isFalse);
      expect(undo.docs, old);

      await s.stage(undo);
      await e.recover();
      await e.finalize(() async {});
      expect(await BackupScope.collect(live, appBackupRegistry), old);
    });

    test('tanpa cadangan pengaman: safetyCopy dan inspectSafetyCopy kosong', () async {
      expect((await service().safetyCopy()).getOrElse((_) => throw StateError('Left')), isNull);
      expect((await service().inspectSafetyCopy()).getOrElse((_) => throw StateError('Left')), isNull);
    });

    test('pemulihan dari cadangan yang dibuat BackupService sungguhan: bolak-balik identik', () async {
      final docs = sampleDocs(months: ['2026-09', '2026-10']);
      await seed(docs);
      final file = (await BackupService(
        storage: live,
        registry: appBackupRegistry,
        appInfo: () async => (version: '0.8.0', build: 14),
        fileStem: () => 'cadangan',
        now: () => now,
      ).create()).getOrElse((_) => throw StateError('Left'));

      // Ponsel baru: penyimpanan kosong.
      live = InMemoryKeyValueStorage();
      staging = InMemoryKeyValueStorage();
      final s = service();
      await s.stage(ok(await s.inspect(file.bytes, source: RestoreKind.onboarding)));
      final e = engine();
      await e.recover();
      await e.finalize(() async {});
      expect(await BackupScope.collect(live, appBackupRegistry), docs);
    });
  });
}
