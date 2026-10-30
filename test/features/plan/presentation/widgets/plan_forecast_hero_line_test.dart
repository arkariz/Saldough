import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/plan/presentation/widgets/plan_forecast_row.dart';

import '../../../../helpers/reduced_motion.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
  builder: reducedMotion,
  home: Scaffold(
    body: Container(
      width: 360,
      color: DsThemePresets.fallback.light.heroSurface,
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

PlanForecastHeroLine _line({
  required int end,
  required int low,
  VoidCallback? onTap,
}) => PlanForecastHeroLine(
  endDate: DateTime(2026, 10, 31),
  endBalance: end,
  lowDate: DateTime(2026, 10, 24),
  lowBalance: low,
  onTap: onTap ?? () {},
);

void main() {
  final colors = DsThemePresets.fallback.light;

  testWidgets('menampilkan label huruf kapital, nilai perkiraan, dan baris terendah bila lebih rendah', (tester) async {
    await tester.pumpWidget(_host(_line(end: 861500000, low: 500000000)));
    final label = t.plan.forecastEndLabel(date: '31 Okt').toUpperCase();
    expect(find.text(label), findsOneWidget);
    expect(find.byKey(const ValueKey('forecast-end')), findsOneWidget);
    expect(find.byKey(const ValueKey('forecast-lowest')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const ValueKey('forecast-end'))).style!.color, colors.onHero);
  });

  testWidgets('titik terendah sama dengan akhir periode: tanpa baris terendah', (tester) async {
    await tester.pumpWidget(_host(_line(end: 500000000, low: 500000000)));
    expect(find.byKey(const ValueKey('forecast-lowest')), findsNothing);
  });

  testWidgets('saldo negatif memakai kuning terang, bukan merah (kontras di kartu hijau)', (tester) async {
    await tester.pumpWidget(_host(_line(end: -100000, low: -200000)));
    expect(tester.widget<Text>(find.byKey(const ValueKey('forecast-end'))).style!.color, colors.heroAccentWarm);
    expect(tester.widget<Text>(find.byKey(const ValueKey('forecast-lowest'))).style!.color, colors.heroAccentWarm);
  });

  testWidgets('ketuk membuka Rencana; target sentuh minimal 44px; tidak luap di 2x teks', (tester) async {
    var taps = 0;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(_host(_line(end: 861500000, low: 500000000, onTap: () => taps++)));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(PlanForecastHeroLine)).height, greaterThanOrEqualTo(44));
    await tester.tap(find.byKey(const ValueKey('forecast-end')));
    expect(taps, 1);
  });
}
