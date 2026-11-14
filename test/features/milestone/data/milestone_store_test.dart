import 'package:api_storage/api_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/milestone/data/milestone_store_impl.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_ledger.dart';

void main() {
  test('belum ditulis: kosong', () async {
    final store = MilestoneStoreImpl(storage: InMemoryKeyValueStorage());
    expect((await store.load()).getOrElse((_) => throw StateError('gagal')), MilestoneLedger.empty);
  });

  test('bolak-balik semua field', () async {
    final store = MilestoneStoreImpl(storage: InMemoryKeyValueStorage());
    final ledger = MilestoneLedger(
      earned: {
        'wallet_first': EarnedMilestone(id: 'wallet_first', earnedAt: DateTime(2026, 11, 14, 9), seen: true),
        'record_first': EarnedMilestone(id: 'record_first', earnedAt: DateTime(2026, 11, 14, 10), quiet: true),
      },
      seeded: true,
      introShown: true,
      celebrationEnabled: false,
    );
    await store.save(ledger);
    expect((await store.load()).getOrElse((_) => throw StateError('gagal')), ledger);
  });

  test('item rusak dilewati tanpa melempar', () async {
    final storage = InMemoryKeyValueStorage();
    await StoredValue<Map<String, dynamic>>.json(
      key: const StorageKey(namespace: 'milestone', name: 'ledger'),
      fromJson: (json) => json,
      toJson: (json) => json,
      storage: storage,
    ).write({
      'earned': [
        {'id': 'a', 'earnedAt': 'rusak'},
        {'id': 'b', 'earnedAt': '2026-11-14T00:00:00.000'},
        'bukan-peta',
      ],
    });
    final ledger = (await MilestoneStoreImpl(storage: storage).load()).getOrElse((_) => throw StateError('gagal'));
    expect(ledger.earned.keys, ['b']);
    expect(ledger.celebrationEnabled, isTrue);
  });
}
