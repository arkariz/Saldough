import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/app_hard_card.dart';
import 'package:saldough/core/theme/theme.dart';

void main() {
  Future<BoxDecoration> pumpAndGetDecoration(
    WidgetTester tester, {
    AppHardElevation elevation = AppHardElevation.card,
    bool pressed = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PixelTheme(
          child: Scaffold(
            body: AppHardCard(
              elevation: elevation,
              pressed: pressed,
              child: const Text('isi'),
            ),
          ),
        ),
      ),
    );
    final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    return container.decoration! as BoxDecoration;
  }

  group('AppHardCard', () {
    testWidgets('level card memakai garis tepi 2px dan bayangan offset 3px (ADR-015)', (tester) async {
      final decoration = await pumpAndGetDecoration(tester);
      final border = decoration.border! as Border;
      expect(border.top.width, AppBorder.pixelThick);
      expect(decoration.boxShadow, isNotEmpty);
      expect(decoration.boxShadow!.single.offset, const Offset(AppElevation.pixelCard, AppElevation.pixelCard));
    });

    testWidgets('level flat tanpa bayangan', (tester) async {
      final decoration = await pumpAndGetDecoration(tester, elevation: AppHardElevation.flat);
      expect(decoration.boxShadow, isEmpty);
    });

    testWidgets('level interactive memakai offset bayangan 4px', (tester) async {
      final decoration = await pumpAndGetDecoration(tester, elevation: AppHardElevation.interactive);
      expect(
        decoration.boxShadow!.single.offset,
        const Offset(AppElevation.pixelInteractive, AppElevation.pixelInteractive),
      );
    });

    testWidgets('level interactive yang ditekan menekan bayangan ke 0', (tester) async {
      final decoration = await pumpAndGetDecoration(tester, elevation: AppHardElevation.interactive, pressed: true);
      expect(decoration.boxShadow!.single.offset, Offset.zero);
    });

    testWidgets('level bottomSheet memakai bayangan mengarah ke atas, garis tepi tiga sisi', (tester) async {
      final decoration = await pumpAndGetDecoration(tester, elevation: AppHardElevation.bottomSheet);
      expect(decoration.boxShadow!.single.offset, const Offset(0, -AppElevation.pixelInteractive));
      final border = decoration.border! as Border;
      expect(border.bottom, BorderSide.none);
      expect(border.top.width, AppBorder.pixelThick);
    });

    testWidgets('radius bawaan pixelSm (4px)', (tester) async {
      final decoration = await pumpAndGetDecoration(tester);
      expect(decoration.borderRadius, AppRadius.pixelSmAll);
    });
  });
}
