import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

void main() {
  testWidgets('target sentuh minimal 44×44 dan diumumkan sebagai tombol', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: Center(
            child: AppQuickChip(label: '+1', onTap: () => taps++),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(AppQuickChip));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
    expect(tester.getSemantics(find.byType(AppQuickChip)), isSemantics(isButton: true, label: '+1'));

    await tester.tap(find.byType(AppQuickChip));
    expect(taps, 1);
  });
}
