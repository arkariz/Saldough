import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';

void main() {
  testWidgets('DsInlineActions: aksi selebar sama, tinggi sama, area sentuh 44', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: DsInlineActions(
              actions: [
                DsInlineAction(label: 'Lewati', onPressed: () {}),
                DsInlineAction(label: 'Ubah dulu', onPressed: () {}),
                DsInlineAction(label: 'Catat', tone: DsInlineActionTone.primary, onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    final rects = tester.widgetList(find.byType(DsInlineAction)).map((w) => tester.getRect(find.byWidget(w))).toList();
    expect(rects, hasLength(3));
    expect(rects.map((r) => r.width.round()).toSet(), hasLength(1), reason: 'lebar sama');
    expect(rects.every((r) => r.height >= 44), isTrue, reason: 'area sentuh min 44');
    expect(rects.map((r) => r.top).toSet(), hasLength(1), reason: 'sebaris');
  });

  testWidgets('DsInlineAction: label panjang mengecil, tidak meluap, dan bisa ditekan', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
        home: Scaffold(
          body: SizedBox(
            width: 90,
            child: DsInlineAction(label: 'Perbarui nominal ke Rp1.250.000', onPressed: () => taps++),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(DsInlineAction));
    expect(taps, 1);
  });
}
