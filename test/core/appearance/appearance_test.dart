import 'package:api_storage/api_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/appearance/appearance.dart';

void main() {
  tearDown(() => ActiveAppearance.notifier.value = AppearanceSettings.initial);

  test('bawaan: preset matcha, mengikuti sistem', () {
    expect(AppearanceSettings.initial.presetId, 'matcha');
    expect(AppearanceSettings.initial.themeMode, ThemeMode.system);
  });

  test('kesetaraan dan copyWith', () {
    const a = AppearanceSettings(presetId: 'pink', themeMode: ThemeMode.dark);
    expect(a, const AppearanceSettings(presetId: 'pink', themeMode: ThemeMode.dark));
    expect(a.copyWith(themeMode: ThemeMode.light).presetId, 'pink');
    expect(a.copyWith(presetId: 'matcha').themeMode, ThemeMode.dark);
  });

  test('repository: bawaan saat kosong, menyimpan dan membaca balik', () async {
    final repository = AppearanceRepositoryImpl(storage: InMemoryKeyValueStorage());
    expect((await repository.load()).getOrElse((_) => const AppearanceSettings(presetId: 'x', themeMode: ThemeMode.dark)), AppearanceSettings.initial);
    const saved = AppearanceSettings(presetId: 'pink', themeMode: ThemeMode.dark);
    await repository.save(saved);
    expect((await repository.load()).getOrElse((_) => AppearanceSettings.initial), saved);
  });

  test('repository: mode tak dikenal jatuh ke sistem, preset kosong ke bawaan', () async {
    final storage = InMemoryKeyValueStorage();
    final repository = AppearanceRepositoryImpl(storage: storage);
    await StoredValue<Map<String, Object?>>.json(
      key: const StorageKey(namespace: 'settings', name: 'appearance'),
      fromJson: (json) => json,
      toJson: (json) => json,
      storage: storage,
    ).write({'schemaVersion': 1, 'mode': 'aneh'});
    final loaded = (await repository.load()).getOrElse((_) => const AppearanceSettings(presetId: 'x', themeMode: ThemeMode.dark));
    expect(loaded.themeMode, ThemeMode.system);
    expect(loaded.presetId, 'matcha');
  });

  test('notifier memberi tahu pendengar', () {
    var calls = 0;
    ActiveAppearance.notifier.addListener(() => calls++);
    ActiveAppearance.notifier.value = const AppearanceSettings(presetId: 'pink', themeMode: ThemeMode.light);
    expect(calls, 1);
    expect(ActiveAppearance.value.presetId, 'pink');
  });
}
