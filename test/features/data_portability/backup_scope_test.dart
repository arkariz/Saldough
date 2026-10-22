import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/app/data_portability/app_backup_registry.dart';
import 'package:saldough/features/data_portability/data/backup_scope.dart';

import '../../helpers/backup_docs.dart';

/// Cakupan cadangan (ADR-040 §3.3).
void main() {
  late InMemoryKeyValueStorage storage;

  setUp(() => storage = InMemoryKeyValueStorage());

  Future<void> seed(Map<String, String> docs) async {
    for (final e in docs.entries) {
      await storage.write(e.key, e.value);
    }
  }

  test('mengumpulkan kunci tetap, partisi transaksi, dan ikon sumber yang dirujuk', () async {
    final docs = sampleDocs(months: ['2026-09', '2026-10']);
    await seed(docs);
    expect(await BackupScope.collect(storage, appBackupRegistry), docs);
  });

  test('kunci milik perangkat dan di luar daftar tidak ikut', () async {
    await seed(sampleDocs());
    await storage.write('settings_language', '{"schemaVersion":1,"code":"en"}');
    await storage.write('capture_inbox', '{"items":[]}');
    await storage.write('tutorial_progress', '{}');
    final scope = await BackupScope.collect(storage, appBackupRegistry);
    expect(scope.keys, isNot(contains('settings_language')));
    expect(scope.keys, isNot(contains('capture_inbox')));
    expect(scope.keys, isNot(contains('tutorial_progress')));
  });

  test('bulan yang hilang dari indeks tetapi ada di antara bulan lain tetap ditemukan', () async {
    final docs = sampleDocs(months: ['2026-07', '2026-10']);
    await seed(docs);
    // Partisi Agustus ada, tetapi indeks hanya mencatat Juli dan Oktober.
    await storage.write('transaction_2026-08', '{"schemaVersion":2,"items":[]}');
    final scope = await BackupScope.collect(storage, appBackupRegistry);
    expect(scope.keys, contains('transaction_2026-08'));
    expect(scope.keys, isNot(contains('transaction_2026-09')));
  });

  test('indeks menyebut bulan tanpa dokumen: dilewati, bukan galat', () async {
    await seed(sampleDocs(months: ['2026-10']));
    await storage.remove('transaction_2026-10');
    final scope = await BackupScope.collect(storage, appBackupRegistry);
    expect(scope.keys, isNot(contains('transaction_2026-10')));
    expect(scope.keys, contains('transaction__index'));
  });

  test('ikon yang dirujuk tetapi tidak tersimpan dilewati', () async {
    await seed(sampleDocs());
    await storage.remove('source_icon_ic1');
    final scope = await BackupScope.collect(storage, appBackupRegistry);
    expect(scope.keys, isNot(contains('source_icon_ic1')));
  });

  test('penyimpanan kosong: cakupan kosong', () async {
    expect(await BackupScope.collect(storage, appBackupRegistry), isEmpty);
  });
}
