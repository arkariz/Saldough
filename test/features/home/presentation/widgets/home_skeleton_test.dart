import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/features/home/presentation/widgets/home_skeleton.dart';

Widget _host({bool reduced = false}) => MaterialApp(
  theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: child!,
  ),
  home: const Scaffold(body: HomeSkeleton()),
);

void main() {
  testWidgets('kerangka tampil sesudah jeda, bukan langsung', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.byType(DsSkeleton), findsNothing);
    await tester.pump(HomeSkeleton.delay + const Duration(milliseconds: 50));
    expect(find.byType(DsSkeleton), findsWidgets);
  });

  testWidgets('berdenyut, dan diam saat animasi dikurangi', (tester) async {
    Color? colorAt() {
      final box = tester.widget<Container>(find.descendant(of: find.byType(DsSkeleton), matching: find.byType(Container)).first);
      return (box.decoration! as BoxDecoration).color;
    }

    await tester.pumpWidget(_host());
    await tester.pump(HomeSkeleton.delay + const Duration(milliseconds: 50));
    final before = colorAt();
    await tester.pump(const Duration(milliseconds: 400));
    expect(colorAt(), isNot(before));

    await tester.pumpWidget(_host(reduced: true));
    await tester.pump(HomeSkeleton.delay + const Duration(milliseconds: 50));
    final still = colorAt();
    await tester.pump(const Duration(milliseconds: 400));
    expect(colorAt(), still);
  });

  testWidgets('tidak luap di 360px dengan teks 2x', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(_host());
    await tester.pump(HomeSkeleton.delay + const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
  });
}
