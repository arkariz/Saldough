import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';

Widget _host({bool reduced = false}) => MaterialApp(
  theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
  builder: (c, child) => MediaQuery(
    data: MediaQuery.of(c).copyWith(disableAnimations: reduced),
    child: child!,
  ),
  home: Scaffold(
    body: ListView(
      cacheExtent: 2000,
      children: [
        for (var i = 0; i < 12; i++)
          DsScrollReveal(
            child: SizedBox(height: 300, child: Center(child: Text('baris $i'))),
          ),
      ],
    ),
  ),
);

double _opacity(WidgetTester tester, String text) {
  final finder = find.ancestor(
    of: find.text(text, skipOffstage: false),
    matching: find.byType(Opacity, skipOffstage: false),
  );
  return tester.widget<Opacity>(finder.first).opacity;
}

void main() {
  testWidgets('baris yang sudah terlihat penuh; yang di bawah lipatan transparan lalu masuk saat digulir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host());
    await tester.pump();
    await tester.pump();
    expect(_opacity(tester, 'baris 0'), 1);
    // Baris 5 (y ≈ 800) di luar layar: belum masuk.
    expect(_opacity(tester, 'baris 3'), lessThan(0.2));

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    await tester.pump();
    expect(_opacity(tester, 'baris 3'), greaterThan(0.9), reason: 'sudah masuk layar');
    // Baris 0 sudah keluar lewat atas: meredup.
    expect(find.text('baris 0').hitTestable(), findsNothing);
  });

  testWidgets('gerak dikurangi: tanpa efek', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(reduced: true));
    await tester.pump();
    expect(find.ancestor(of: find.text('baris 3'), matching: find.byType(Opacity)), findsNothing);
  });
}
