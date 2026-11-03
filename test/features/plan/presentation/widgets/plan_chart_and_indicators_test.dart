import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/plan/presentation/widgets/plan_balance_chart.dart';
import 'package:saldough/features/plan/presentation/widgets/plan_distribution.dart';
import 'package:saldough/features/plan/presentation/widgets/plan_indicators.dart';
import 'package:saldough/shared/recurring/recurring.dart';

import '../../../../helpers/reduced_motion.dart';

Widget _host(Widget child, {double width = 360}) => MaterialApp(
  builder: reducedMotion,
  theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: SingleChildScrollView(child: child),
      ),
    ),
  ),
);

MonthPlan _plan({int bills = 588000000, int budget = 306850000, int offPlan = 5700000}) => MonthPlan(
  plannedIncome: 1200000000,
  recordedIncome: 0,
  plannedRecurringOut: bills,
  recordedRecurringOut: 0,
  budgetPlanned: budget,
  budgetSpent: 36850000,
  unplannedOut: offPlan,
  unplannedIn: 0,
  budgetOverrun: 0,
  recurringDifference: 0,
  moved: 0,
  hasEstimate: false,
);

void main() {
  final days = <ProjectedDay>[
    for (var i = 0; i < 20; i++)
      (date: DateTime(2026, 10, 2 + i), balance: 650000000 - (i < 10 ? i * 20000000 : (20 - i) * 5000000) - 100000000),
  ];
  final low = days.reduce((a, b) => a.balance <= b.balance ? a : b);

  group('PlanBalanceChart', () {
    testWidgets('fokus awal di titik terendah dengan tooltip; ketuk memindahkan fokus', (tester) async {
      await tester.pumpWidget(_host(PlanBalanceChart(days: days, low: low, isFuture: false)));
      await tester.pump();
      expect(find.text(t.plan.lowestOn(date: '${low.date.day} Okt')), findsOneWidget);

      // Ketuk di tepi kiri area gambar: fokus pindah ke hari pertama.
      final box = tester.getRect(find.byType(PlanBalanceChart));
      await tester.tapAt(Offset(box.left + 40, box.top + 120));
      await tester.pump();
      expect(find.text(t.plan.lowestOn(date: '${low.date.day} Okt')), findsNothing);
      expect(find.text('2 Okt'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('muat di 280dp dengan teks 200% dan saldo negatif tanpa luapan', (tester) async {
      final negative = <ProjectedDay>[
        for (var i = 0; i < 12; i++) (date: DateTime(2026, 10, 2 + i), balance: (i - 6) * 30000000),
      ];
      await tester.pumpWidget(
        MaterialApp(
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c).copyWith(disableAnimations: true, textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
          home: Scaffold(
            body: SizedBox(
              width: 280,
              child: PlanBalanceChart(days: negative, low: negative.first, isFuture: true),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('label sumbu ringkas', () {
      expect(axisLabel(0), '0');
      expect(axisLabel(85000000), '850 rb');
      expect(axisLabel(1000000000), '10 jt');
      expect(axisLabel(-250000000), '−2,5 jt');
    });
  });

  group('PlanIndicators', () {
    testWidgets('empat kartu dengan angka dari rencana; tanpa riwayat tampil strip', (tester) async {
      await tester.pumpWidget(
        _host(PlanIndicators(plan: _plan(), lowest: low, committedShare: 75, previousShare: 49, unplannedPerDay: null)),
      );
      await tester.pump();
      expect(find.text('75%'), findsOneWidget);
      expect(find.text(t.plan.indLockedPrev(percent: 49)), findsOneWidget);
      expect(find.text('12%'), findsOneWidget, reason: '36,85 jt dari 306,85 jt');
      expect(find.text('—'), findsOneWidget);
      expect(find.text(t.plan.indPerDayNone), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('PlanDistribution', () {
    testWidgets('tiga baris dengan persen; tersembunyi tanpa pengeluaran', (tester) async {
      await tester.pumpWidget(_host(PlanDistribution(plan: _plan())));
      await tester.pump();
      expect(find.text(t.plan.distTitle), findsOneWidget);
      expect(find.text(t.plan.billsRow), findsOneWidget);
      expect(find.text(t.plan.offPlanRow), findsOneWidget);

      await tester.pumpWidget(_host(PlanDistribution(plan: _plan(bills: 0, budget: 0, offPlan: 0))));
      await tester.pump();
      expect(find.text(t.plan.distTitle), findsNothing);
    });
  });
}
