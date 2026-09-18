import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/theme/theme.dart';

void main() {
  group('PixelTheme', () {
    testWidgets('context.appColors di dalam subtree mengembalikan pixelLight, bukan AppTheme.light', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: PixelTheme(child: Builder(builder: (context) => Text(context.appColors.income.toString()))),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, AppColorsExtension.pixelLight.income.toString());
      expect(text.data, isNot(AppColorsExtension.light.income.toString()));
    });

    testWidgets('di luar PixelTheme, context.appColors tetap AppTheme.light (layar lama tidak terpengaruh)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(builder: (context) => Text(context.appColors.income.toString())),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, AppColorsExtension.light.income.toString());
    });

    testWidgets('textTheme.headlineSmall memakai Space Grotesk di dalam PixelTheme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: PixelTheme(child: Builder(builder: (context) => Text('x', style: Theme.of(context).textTheme.headlineSmall))),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.fontFamily, contains('SpaceGrotesk'));
    });

    testWidgets('textTheme.bodyMedium memakai Plus Jakarta Sans di dalam PixelTheme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: PixelTheme(child: Builder(builder: (context) => Text('x', style: Theme.of(context).textTheme.bodyMedium))),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.fontFamily, contains('PlusJakartaSans'));
    });

    testWidgets('PixelTheme tetap berlaku di dalam showModalBottomSheet (InheritedTheme.capture)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: PixelTheme(
            child: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => Text(context.appColors.income.toString()),
                  ),
                  child: const Text('buka'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();

      final sheetText = tester.widget<Text>(find.text(AppColorsExtension.pixelLight.income.toString()));
      expect(sheetText.data, AppColorsExtension.pixelLight.income.toString());
    });

    testWidgets('memilih pixelDark saat ambient brightness gelap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: PixelTheme(child: Builder(builder: (context) => Text(context.appColors.income.toString()))),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, AppColorsExtension.pixelDark.income.toString());
    });
  });
}
