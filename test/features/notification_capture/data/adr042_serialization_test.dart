import 'package:api_storage/api_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// ADR-042: field baru bolak-balik, dan dokumen lama tetap terbaca.
void main() {
  test('setelan: aturan dompet dan saveSamples bolak-balik', () async {
    final store = NotificationCaptureStoreImpl(storage: InMemoryKeyValueStorage());
    const settings = NotificationCaptureSettings(
      enabled: true,
      saveSamples: true,
      sources: [
        NotificationSource(
          packageName: 'com.jago',
          appLabel: 'Jago',
          walletId: 'main',
          walletRules: [
            WalletRule(walletId: 'trip', keywords: ['Kantong Liburan']),
          ],
        ),
      ],
    );
    await store.saveSettings(settings);
    expect((await store.loadSettings()).getOrElse((_) => const NotificationCaptureSettings()), settings);
  });

  test('setelan lama tanpa field baru: tanpa aturan dompet, contoh mati', () async {
    final storage = InMemoryKeyValueStorage();
    final store = NotificationCaptureStoreImpl(storage: storage);
    await store.saveSettings(
      const NotificationCaptureSettings(
        enabled: true,
        sources: [NotificationSource(packageName: 'a', appLabel: 'A', walletId: 'w')],
      ),
    );
    final loaded = (await store.loadSettings()).getOrElse((_) => const NotificationCaptureSettings());
    expect(loaded.saveSamples, isFalse);
    expect(loaded.sources.single.walletRules, isEmpty);
  });

  test('rutin lama yang masih memuat ikatan ke pola tetap terbaca; ikatannya diabaikan dan tidak ditulis lagi', () {
    final rule = RecurringRule(
      id: 'r',
      kind: RecurringKind.expense,
      amount: 100,
      walletId: 'w',
      note: 'n',
      schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 9, 29)),
    );
    final json = RecurringRuleModel.toJson(rule)
      ..['notificationBinding'] = {'packageName': 'p', 'patternId': 'x', 'patternLabel': 'L'};
    final read = RecurringRuleModel.fromJson(json);
    expect(read, rule);
    expect(RecurringRuleModel.toJson(read).containsKey('notificationBinding'), isFalse);
  });

  test(
    'pola buatan pengguna dari versi lama dibuang saat dibuka (ADR-044 Revisi 11); kosong = tidak melakukan apa pun',
    () async {
      final storage = InMemoryKeyValueStorage();
      const key = StorageKey(namespace: 'capture', name: 'notification_patterns');
      final value = StoredValue<Map<String, dynamic>>.json(
        key: key,
        fromJson: (json) => json,
        toJson: (json) => json,
        storage: storage,
      );
      await purgeLegacyCapturePatterns(storage);
      expect(await value.read(), isNull, reason: 'tidak ada yang ditulis bila belum ada pola');

      await value.write({
        'schemaVersion': 1,
        'items': [
          {'id': 'u', 'packageName': 'p', 'template': '{amount}', 'kind': 'expense'},
        ],
      });
      await purgeLegacyCapturePatterns(storage);
      expect((await value.read())!['items'], isEmpty);
    },
  );
}
