import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/transaction/data/history_segment_repository_impl.dart';
import 'package:saldough/features/transaction/domain/history_segment.dart';

/// Segmen Riwayat terakhir, per perangkat (FINANCIAL_ANALYSIS §6).
void main() {
  late InMemoryKeyValueStorage storage;
  late HistorySegmentRepositoryImpl repository;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = HistorySegmentRepositoryImpl(storage: storage);
  });

  HistorySegment read(Either<Failure, HistorySegment> result) =>
      result.getOrElse((_) => throw StateError('expected Right'));

  test('belum pernah dipilih: Daftar', () async {
    expect(read(await repository.load()), HistorySegment.list);
  });

  test('segmen tersimpan dan terbaca ulang', () async {
    await repository.save(HistorySegment.analysis);
    expect(read(await repository.load()), HistorySegment.analysis);
    await repository.save(HistorySegment.list);
    expect(read(await repository.load()), HistorySegment.list);
  });

  test('nilai yang tidak dikenal dibaca sebagai Daftar', () async {
    const key = StorageKey(namespace: 'settings', name: 'history_segment');
    await storage.write(key.value, '{"schemaVersion":1,"segment":"tahun"}');
    expect(read(await repository.load()), HistorySegment.list);
  });
}
