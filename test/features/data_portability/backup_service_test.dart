import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/app/data_portability/app_backup_registry.dart';
import 'package:saldough/features/data_portability/data/backup_codec.dart';
import 'package:saldough/features/data_portability/data/backup_scope.dart';
import 'package:saldough/features/data_portability/data/backup_service.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/export_models.dart';

import '../../helpers/backup_docs.dart';

/// Cadangkan sekarang (EXPORT_BACKUP §6, ADR-040 §3.5).
void main() {
  late InMemoryKeyValueStorage storage;
  var now = DateTime(2026, 10, 22, 9);

  BackupService service() => BackupService(
    storage: storage,
    registry: appBackupRegistry,
    appInfo: () async => (version: '0.8.0', build: 14),
    fileStem: () => 'cadangan',
    now: () => now,
  );

  Future<void> seed(Map<String, String> docs) async {
    for (final e in docs.entries) {
      await storage.write(e.key, e.value);
    }
  }

  setUp(() {
    storage = InMemoryKeyValueStorage();
    now = DateTime(2026, 10, 22, 9);
  });

  test('summary: jumlah transaksi, dompet, tanggal awal, dan mata uang dari data sekarang', () async {
    await seed(sampleDocs(months: ['2026-09', '2026-10']));
    final summary = (await service().summary()).getOrElse((_) => throw StateError('Left'));
    expect((summary.transactions, summary.wallets, summary.firstDate, summary.currency), (2, 2, '2026-09-03', 'IDR'));
  });

  test('create: berkas bernama dengan tanggal dan ekstensi .tkbak, isinya dokumen apa adanya', () async {
    final docs = sampleDocs(months: ['2026-09', '2026-10']);
    await seed(docs);
    final file = (await service().create()).getOrElse((_) => throw StateError('Left'));

    expect(file.name, 'tanukonomy-cadangan-2026-10-22.tkbak');
    expect(file.createdAt, now);
    expect(file.summary.transactions, 2);

    final contents = BackupCodec.decode(file.bytes);
    expect(contents.docs, docs);
    expect((contents.appVersion, contents.appBuild), ('0.8.0', 14));
    expect(contents.createdAt, now);
  });

  test('create tidak mengubah data (C-4) dan tidak menyentuh kunci milik perangkat', () async {
    await seed(sampleDocs());
    await storage.write('settings_language', '{"schemaVersion":1,"code":"en"}');
    final before = await BackupScope.collect(storage, appBackupRegistry);
    final file = (await service().create()).getOrElse((_) => throw StateError('Left'));

    expect(await BackupScope.collect(storage, appBackupRegistry), before);
    expect(await storage.read('settings_language'), '{"schemaVersion":1,"code":"en"}');
    expect(BackupCodec.decode(file.bytes).docs.keys, isNot(contains('settings_language')));
  });

  test('penyimpanan kosong tetap bisa dicadangkan (hanya setelan, tanpa transaksi)', () async {
    final file = (await service().create()).getOrElse((_) => throw StateError('Left'));
    expect(file.summary.transactions, 0);
    expect(BackupCodec.decode(file.bytes).docs, isEmpty);
  });

  test('data yang tidak konsisten tidak diserahkan sebagai cadangan (diperiksa lagi sebelum diserahkan)', () async {
    final docs = sampleDocs()..['wallet_all'] = '{"schemaVersion":1,"items":[]}';
    await seed(docs);
    final result = await service().create();
    expect(result.swap().getOrElse((_) => throw StateError('Right')).code, BackupFailureCodes.inconsistent);
  });

  test('dibatalkan: cancelled', () async {
    await seed(sampleDocs());
    final cancel = ExportCancel()..cancel();
    final result = await service().create(cancel: cancel);
    expect(result.swap().getOrElse((_) => throw StateError('Right')).code, BackupFailureCodes.cancelled);
  });

  test('Cadangan terakhir: belum pernah → null; sesudah dicatat → waktunya; tidak ikut cadangan', () async {
    final s = service();
    expect((await s.lastBackupAt()).getOrElse((_) => throw StateError('Left')), isNull);
    await s.recordBackup();
    expect((await s.lastBackupAt()).getOrElse((_) => throw StateError('Left')), now);

    await seed(sampleDocs());
    final file = (await s.create()).getOrElse((_) => throw StateError('Left'));
    expect(BackupCodec.decode(file.bytes).docs.keys, isNot(contains(lastBackupStorageKey.value)));
  });

  test('membuat cadangan saja tidak memperbarui Cadangan terakhir (hanya bila tersimpan)', () async {
    await seed(sampleDocs());
    final s = service();
    await s.create();
    expect((await s.lastBackupAt()).getOrElse((_) => throw StateError('Left')), isNull);
  });
}
