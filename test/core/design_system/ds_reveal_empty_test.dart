import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

Widget _host(Widget child, {bool reduced = false}) => MaterialApp(
  theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: child!,
  ),
  home: Scaffold(body: Center(child: child)),
);

double _opacityOf(WidgetTester tester) => tester
    .widget<FadeTransition>(find.descendant(of: find.byType(DsReveal), matching: find.byType(FadeTransition)))
    .opacity
    .value;

void main() {
  group('DsReveal', () {
    testWidgets('muncul bertahap dari transparan; urutan menunda mulai', (tester) async {
      await tester.pumpWidget(_host(const DsReveal(index: 3, child: Text('isi'))));
      expect(_opacityOf(tester), 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_opacityOf(tester), 0, reason: 'tunda 180 ms belum lewat');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));
      expect(_opacityOf(tester), 1);
    });

    testWidgets('gerak dikurangi: langsung tampil penuh', (tester) async {
      await tester.pumpWidget(_host(const DsReveal(index: 5, child: Text('isi')), reduced: true));
      expect(_opacityOf(tester), 1);
    });
  });

  group('DsEmptyHero', () {
    testWidgets('berputar terus; berhenti saat gerak dikurangi', (tester) async {
      await tester.pumpWidget(_host(const DsEmptyHero(asset: ClayIcons.piggy, orbit: [ClayIcons.cash])));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(seconds: 5));
      expect(tester.hasRunningAnimations, isTrue, reason: 'loop tidak berakhir');
      await tester.pumpWidget(
        _host(const DsEmptyHero(asset: ClayIcons.piggy, orbit: [ClayIcons.cash]), reduced: true),
      );
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  testWidgets('DsSegmentMeter: segmen terisi menyala berurutan lalu penuh', (tester) async {
    await tester.pumpWidget(_host(const SizedBox(width: 200, child: DsSegmentMeter(value: 0.5, semanticLabel: '50%'))));
    Color? lastFilled() {
      final boxes = tester
          .widgetList<DecoratedBox>(
            find.descendant(of: find.byType(DsSegmentMeter), matching: find.byType(DecoratedBox)),
          )
          .map((b) => (b.decoration as BoxDecoration).color)
          .toList();
      return boxes[4];
    }

    final start = lastFilled();
    await tester.pump(const Duration(seconds: 2));
    expect(lastFilled(), isNot(start));
  });
}
