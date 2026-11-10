import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/app/shell/appearance_quick_action.dart';
import 'package:saldough/core/appearance/appearance.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';

void main() {
  tearDown(() => ActiveAppearance.notifier.value = AppearanceSettings.initial);

  testWidgets('tile Warna membuka pilihan preset dan menyimpan pilihannya', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
        home: const Scaffold(body: Row(children: [Expanded(child: AppearanceQuickAction())])),
      ),
    );
    expect(find.text(t.home.actionAppearance), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-action-appearance')));
    await tester.pumpAndSettle();
    expect(find.text(t.appearance.presetPickerTitle), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('appearance-preset-tanuki')));
    await tester.pumpAndSettle();
    expect(ActiveAppearance.value.presetId, 'tanuki');
  });
}
