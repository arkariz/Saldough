import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Pemilih periode ‹ periode › (komponen PeriodStepper).
void main() {
  Future<void> pump(
    WidgetTester tester, {
    VoidCallback? onPrevious,
    VoidCallback? onNext,
    int? transitionDays,
    String title = 'September 2026',
  }) => tester.pumpWidget(
    MaterialApp(
      theme: PixelTheme.light,
      home: Scaffold(
        body: AppPeriodStepper(title: title, transitionDays: transitionDays, onPrevious: onPrevious, onNext: onNext),
      ),
    ),
  );

  AppIconButton button(WidgetTester tester, String key) => tester.widget<AppIconButton>(find.byKey(ValueKey(key)));

  testWidgets('judul dan dua panah; mundur dan maju memanggil pemanggilnya', (tester) async {
    var back = 0;
    var forward = 0;
    await pump(tester, onPrevious: () => back++, onNext: () => forward++);
    expect(find.text('September 2026'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('period-previous')));
    await tester.tap(find.byKey(const ValueKey('period-next')));
    expect([back, forward], [1, 1]);
    expect(find.byType(AppPeriodTag), findsNothing);
  });

  testWidgets('di periode berjalan panah maju nonaktif; tanpa periode lebih lama panah mundur nonaktif', (tester) async {
    await pump(tester);
    expect(button(tester, 'period-previous').onPressed, isNull);
    expect(button(tester, 'period-next').onPressed, isNull);
  });

  testWidgets('periode peralihan diberi penanda netral dengan panjangnya', (tester) async {
    await pump(tester, title: '1 – 24 Okt', transitionDays: 24, onPrevious: () {});
    expect(find.byType(AppPeriodTag), findsOneWidget);
    expect(find.text('Periode peralihan · 24 hari'), findsOneWidget);
  });

  testWidgets('judul rentang panjang tetap muat di 360dp', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, title: '25\u00A0Agt\u00A0–\u00A024\u00A0Sep', transitionDays: 37, onPrevious: () {}, onNext: () {});
    expect(tester.takeException(), isNull);
  });
}
