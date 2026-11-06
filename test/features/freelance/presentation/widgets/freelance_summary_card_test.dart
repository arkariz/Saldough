import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_cards.dart';

void main() {
  Future<void> pump(WidgetTester tester, {int pendingCount = 0, double scale = 1, double width = 360}) async {
    tester.view
      ..physicalSize = Size(width, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: FreelanceSummaryCard(
              summary: const FreelanceSummary(totalHours: 39, earned: 30000000, paid: 20000000),
              projectCount: 2,
              unbilledHours: 6,
              unbilledAmount: 4500000,
              payments: ProjectPaymentStats(
                pendingCount: pendingCount,
                pendingNet: pendingCount == 0 ? 0 : 5000000,
                nextExpectedDate: pendingCount == 0 ? null : DateTime(2026, 11, 12),
                paidCount: 0,
                paidNet: 0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('ringkasan: belum diterima sebagai angka utama, diterima dan belum ditagih sebagai statistik', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(DsSummaryHero), findsOneWidget);
    expect(find.text(t.freelance.projectCount(count: 2)), findsOneWidget);
    expect(find.text(t.freelance.paidLabel), findsOneWidget);
    expect(find.text(t.freelance.unbilledLabel), findsOneWidget);
    // Tanpa tagihan tertunda, tidak ada baris Tertunda.
    expect(find.text(t.freelance.pendingTotalLabel), findsNothing);
  });

  testWidgets('tagihan tertunda tampil sebagai baris di kaki kartu', (tester) async {
    await pump(tester, pendingCount: 2);
    expect(find.text(t.freelance.pendingTotalLabel), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('360dp teks ${scale}x: tanpa luap', (tester) async {
      await pump(tester, pendingCount: 2, scale: scale);
      expect(tester.takeException(), isNull);
    });
  }
}
