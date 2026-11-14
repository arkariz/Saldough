import 'package:api_storage/api_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/period_book/data/period_book_memory_store_impl.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_memory.dart';

void main() {
  test('belum ditulis: kosong', () async {
    final store = PeriodBookMemoryStoreImpl(storage: InMemoryKeyValueStorage());
    expect((await store.load()).getOrElse((_) => throw StateError('gagal')), PeriodBookMemory.empty);
  });

  test('bolak-balik semua field', () async {
    final store = PeriodBookMemoryStoreImpl(storage: InMemoryKeyValueStorage());
    final memory = PeriodBookMemory.empty
        .withOpened('2026-10-25', DateTime(2026, 11, 14, 9))
        .withStepDone('2026-10-25', 1)
        .withCardDismissed('2026-10-25')
        .withCardFacts({'noteCount', 'stamp'})
        .withInviteEnabled(enabled: false);
    await store.save(memory);
    expect((await store.load()).getOrElse((_) => throw StateError('gagal')), memory);
  });

  test('dokumen rusak sebagian tidak melempar', () async {
    final storage = InMemoryKeyValueStorage();
    await StoredValue<Map<String, dynamic>>.json(
      key: const StorageKey(namespace: 'period_book', name: 'memory'),
      fromJson: (json) => json,
      toJson: (json) => json,
      storage: storage,
    ).write({
      'opened': {'a': 'bukan-tanggal'},
      'ritualSteps': {
        'a': ['x', 1],
      },
    });
    final loaded = (await PeriodBookMemoryStoreImpl(storage: storage).load()).getOrElse((_) => throw StateError('gagal'));
    expect(loaded.opened, isEmpty);
    expect(loaded.stepsOf('a'), {1});
    expect(loaded.inviteEnabled, isTrue);
  });
}
