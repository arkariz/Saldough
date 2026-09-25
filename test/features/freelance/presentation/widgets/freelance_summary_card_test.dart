import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_cards.dart';

void main() {
  testWidgets('bilah porsi diterima/belum diterima benar-benar setinggi 8', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PixelTheme(
          child: Scaffold(
            body: FreelanceSummaryCard(
              summary: FreelanceSummary(totalHours: 39, earned: 300, paid: 200),
              projectCount: 1,
            ),
          ),
        ),
      ),
    );

    final segments = find.descendant(of: find.byType(FreelanceSummaryCard), matching: find.byType(ColoredBox));
    final sizes = [for (final element in segments.evaluate()) tester.getSize(find.byWidget(element.widget))];
    final bar = sizes.where((size) => size.height == 8).toList();
    expect(bar, hasLength(2));
    // Porsi lebarnya mengikuti nominal: 200 diterima, 100 belum.
    expect(bar[0].width, closeTo(bar[1].width * 2, 1));
  });
}
