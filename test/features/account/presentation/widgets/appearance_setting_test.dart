import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/appearance/appearance.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/account/presentation/widgets/appearance_setting.dart';

Widget _host(List<Widget> children) => MaterialApp(
  theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
  home: Scaffold(body: ListView(children: children)),
);

void main() {
  tearDown(() => ActiveAppearance.notifier.value = AppearanceSettings.initial);

  test('setiap preset terdaftar punya nama terjemahan', () {
    // Preset baru wajib menambah `appearance.presets.<id>` dan cabang di
    // `appearancePresetLabel`; daftar ini dijaga supaya tidak terlewat.
    const translated = {'matcha', 'pink', 'taro', 'tanuki', 'laut'};
    expect(DsThemePresets.all.map((p) => p.id).toSet().difference(translated), isEmpty);
  });

  testWidgets('baris mode menampilkan pilihan dan menyimpannya ke notifier', (tester) async {
    await tester.pumpWidget(_host(const [AppearanceModeEntry()]));
    expect(find.textContaining(t.appearance.modeSystem), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('appearance-mode-setting')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('appearance-mode-dark')));
    await tester.pumpAndSettle();
    expect(ActiveAppearance.value.themeMode, ThemeMode.dark);
    expect(ActiveAppearance.value.presetId, 'matcha');
    expect(find.textContaining(t.appearance.modeDark), findsOneWidget);
  });

  testWidgets('baris preset tersembunyi bila hanya satu preset', (tester) async {
    await tester.pumpWidget(_host(const [AppearancePresetEntry(presets: [matcha])]));
    expect(find.byKey(const ValueKey('appearance-preset-setting')), findsNothing);
  });

  testWidgets('baris preset memilih pink dan mempertahankan mode', (tester) async {
    ActiveAppearance.notifier.value = const AppearanceSettings(presetId: 'matcha', themeMode: ThemeMode.dark);
    await tester.pumpWidget(_host(const [AppearancePresetEntry()]));
    await tester.tap(find.byKey(const ValueKey('appearance-preset-setting')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('appearance-preset-pink')));
    await tester.pumpAndSettle();
    expect(ActiveAppearance.value.presetId, 'pink');
    expect(ActiveAppearance.value.themeMode, ThemeMode.dark);
  });

  testWidgets('preset tersimpan yang tak dikenal tampil sebagai bawaan', (tester) async {
    ActiveAppearance.notifier.value = const AppearanceSettings(presetId: 'hilang', themeMode: ThemeMode.system);
    await tester.pumpWidget(_host(const [AppearancePresetEntry()]));
    expect(find.textContaining(appearancePresetLabel(DsThemePresets.fallback.id)), findsOneWidget);
  });
}
