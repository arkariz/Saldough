import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// PeriodHeader (ADR-038, FINANCIAL_PERIOD P-11).
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(theme: PixelTheme.light, home: Scaffold(body: SizedBox(width: 360, child: child))),
  );

  testWidgets('tombol di Bulan ini: ketuk membuka lembar; label menyebut tindakannya', (tester) async {
    var taps = 0;
    await pump(tester, AppPeriodHeader(label: 'Oktober', onTap: () => taps++));
    expect(find.text('Oktober'), findsOneWidget);
    expect(find.byKey(const ValueKey('period-transition-tag')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('period-header')));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.byType(AppPeriodHeader)),
      matchesSemantics(label: 'Oktober. ${t.plan.financialMonthChange}', isButton: true, hasTapAction: true),
    );
  });

  testWidgets('periode peralihan: rentang dan penanda netral', (tester) async {
    await pump(tester, const AppPeriodHeader(label: '1 – 24 Okt', transitionDays: 24));
    expect(find.text('1 – 24 Okt'), findsOneWidget);
    expect(find.text('Periode peralihan · 24 hari'), findsOneWidget);
    // Di Beranda dan Analisis bukan tombol.
    expect(find.byKey(const ValueKey('period-header')), findsNothing);
  });
}
