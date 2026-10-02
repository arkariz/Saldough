import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required ValueChanged<int> onChanged, int selected = 0}) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 740), textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Plan'),
              bottom: AppSubTabs<int>(
                options: [(0, t.appShell.budgetTabLabel), (1, t.plan.recurringSegmentLabel), (2, 'This month')],
                selected: selected,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('label en muat di 360dp dengan skala teks 1,3, dan ketukan memilih segmen', (tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.id));
    int? chosen;
    await pump(tester, onChanged: (value) => chosen = value);

    expect(tester.takeException(), isNull);
    expect(find.text('BUDGET'), findsOneWidget);
    expect(find.text('RECURRING'), findsOneWidget);
    await tester.tap(find.text('RECURRING'));
    expect(chosen, 1);
  });

  testWidgets('segmen aktif diumumkan terpilih ke pembaca layar', (tester) async {
    await pump(tester, onChanged: (_) {}, selected: 1);
    expect(
      tester.getSemantics(find.text(t.plan.recurringSegmentLabel.toUpperCase())),
      isSemantics(isSelected: true, isButton: true),
    );
  });
}
