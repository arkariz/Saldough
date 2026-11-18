import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/savings_goal/presentation/widgets/goal_estimate_section.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';

/// Bagian perkiraan di rincian tujuan (T-30.7).
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: PixelTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  testWidgets('laju, skenario uang nganggur, dan peringatan melewati target', (tester) async {
    await pump(
      tester,
      GoalEstimateSection(
        estimate: SavingsGoalEstimate(
          rate: 300000,
          rateDate: DateTime(2027, 3),
          idleRate: 700000,
          idleDate: DateTime(2027),
          beyondTarget: true,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('goal-estimate-rate')), findsOneWidget);
    expect(find.byKey(const ValueKey('goal-estimate-idle')), findsOneWidget);
    expect(find.text(t.assets.goal.estimate.beyondTarget), findsOneWidget);
    expect(find.text(t.assets.goal.estimate.footnote), findsOneWidget);
  });

  testWidgets('belum bisa diperkirakan: alasan tampil, tanpa skenario dan peringatan', (tester) async {
    await pump(tester, const GoalEstimateSection(estimate: SavingsGoalEstimate(blocker: GoalEstimateBlocker.notSaving)));
    expect(find.text(t.assets.goal.estimate.notYet), findsOneWidget);
    expect(find.text(t.assets.goal.estimate.notSaving), findsOneWidget);
    expect(find.byKey(const ValueKey('goal-estimate-idle')), findsNothing);
    expect(find.text(t.assets.goal.estimate.beyondTarget), findsNothing);
  });

  testWidgets('Gratis: baris terkunci membuka paywall', (tester) async {
    var tapped = 0;
    await pump(tester, GoalEstimateLocked(onTap: () => tapped++));
    await tester.tap(find.byKey(const ValueKey('goal-estimate-locked')));
    expect(tapped, 1);
  });
}
