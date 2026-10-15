import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/app_update/data/app_update_memory_repository_impl.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late AppUpdateMemoryRepositoryImpl repository;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = AppUpdateMemoryRepositoryImpl(storage: storage);
  });

  Future<AppUpdateMemory> loaded() async => (await repository.load()).getOrElse((_) => throw StateError('Left'));

  test('belum ada dokumen berarti ingatan kosong (pemasangan pertama)', () async {
    expect(await loaded(), AppUpdateMemory.empty);
  });

  test('menyimpan lalu membaca kembali semua bidang', () async {
    final memory = AppUpdateMemory.empty.see(7, 1).defer(8, DateTime(2026, 10, 15, 9)).announce(7, 1).announce(6, 3);
    await repository.save(memory);
    expect(await loaded(), memory);
  });

  test('dokumen rusak menghasilkan Left; dokumen baru menimpanya', () async {
    await storage.write('app_update_memory', '{bukan json');
    expect((await repository.load()).isLeft(), isTrue);
    await repository.save(AppUpdateMemory.empty.see(7, 0));
    expect((await loaded()).lastSeenBuild, 7);
  });
}
