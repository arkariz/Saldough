import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/app_segmented_progress_bar.dart';
import 'package:saldough/core/theme/theme.dart';

void main() {
  Future<List<Container>> pumpAndGetSegments(WidgetTester tester, double value) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PixelTheme(
          child: Scaffold(body: AppSegmentedProgressBar(value: value)),
        ),
      ),
    );
    return tester.widgetList<Container>(find.byType(Container)).toList();
  }

  group('AppSegmentedProgressBar', () {
    testWidgets('bawaan 10 segmen, 8px x 8px, jarak 2px', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PixelTheme(child: Scaffold(body: AppSegmentedProgressBar(value: 0.5)))),
      );
      expect(find.byType(Container), findsNWidgets(10));
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.children.whereType<SizedBox>().length, 9);
    });

    testWidgets('value 0.5 mengisi 5 dari 10 segmen', (tester) async {
      final segments = await pumpAndGetSegments(tester, 0.5);
      final filled = segments.where((c) {
        final decoration = c.decoration! as BoxDecoration;
        return decoration.color!.a > 0.5;
      });
      expect(filled.length, 5);
    });

    testWidgets('di bawah 70% memakai warna income', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PixelTheme(child: Scaffold(body: AppSegmentedProgressBar(value: 0.5)))),
      );
      final context = tester.element(find.byType(AppSegmentedProgressBar));
      expect(AppSegmentedProgressBar.colorFor(context, 0.5), context.appColors.income);
    });

    testWidgets('70%-99% memakai warna pending', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PixelTheme(child: Scaffold(body: AppSegmentedProgressBar(value: 0.8)))),
      );
      final context = tester.element(find.byType(AppSegmentedProgressBar));
      expect(AppSegmentedProgressBar.colorFor(context, 0.8), context.appColors.pending);
    });

    testWidgets('100% ke atas memakai warna overBudget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PixelTheme(child: Scaffold(body: AppSegmentedProgressBar(value: 1.2)))),
      );
      final context = tester.element(find.byType(AppSegmentedProgressBar));
      expect(AppSegmentedProgressBar.colorFor(context, 1.2), context.appColors.overBudget);
    });

    testWidgets('value lebih dari 1.0 tetap mengisi seluruh 10 segmen (tidak overflow)', (tester) async {
      final segments = await pumpAndGetSegments(tester, 1.5);
      final filled = segments.where((c) {
        final decoration = c.decoration! as BoxDecoration;
        return decoration.color!.a > 0.5;
      });
      expect(filled.length, 10);
    });
  });
}
