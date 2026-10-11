import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/plan/presentation/widgets/unplanned_card.dart';
import 'package:saldough/features/recurring/presentation/recurring_display.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Nol ditulis "Rp0" tanpa tanda di rincian (T-18.18, QA T-18.9 PO-6).
void main() {
  testWidgets('Tagihan rutin nol: "Rp0", bukan "+Rp0"', (tester) async {
    const plan = MonthPlan(
      plannedIncome: 1200000000,
      recordedIncome: 0,
      plannedRecurringOut: 0,
      recordedRecurringOut: 0,
      budgetPlanned: 306850000,
      budgetSpent: 0,
      unplannedOut: 0,
      unplannedIn: 0,
      budgetOverrun: 0,
      recurringDifference: 0,
      moved: 0,
      hasEstimate: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: UnplannedCard(plan: plan, monthLabel: 'Okt', onShowRecurring: () {}, onShowBudget: () {}),
          ),
        ),
      ),
    );
    expect(find.text(t.plan.billsRow), findsOneWidget);
    expect(find.text('Rp0'), findsOneWidget);
    expect(find.text('+Rp0'), findsNothing);
    expect(find.text('+Rp12.000.000'), findsOneWidget);
    expect(find.text('−Rp3.068.500'), findsOneWidget);
  });

  test('nominal rutin nol tanpa tanda', () {
    expect(signedAmount(RecurringKind.expense, 0), 'Rp0');
    expect(signedAmount(RecurringKind.income, 650000), '+Rp6.500');
  });

  test('id dan en: rentang tidak dipenggal, label selisih dan tawaran tunggal (T-18.18)', () async {
    final period = FinancialPeriod(start: DateTime(2026, 10, 25), end: DateTime(2026, 11, 25));
    expect(period.rangeLabel, '25 Okt – 24 Nov');
    expect(t.home.flowNet, 'Selisih');
    await LocaleSettings.setLocale(AppLocale.en);
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.id));
    expect(period.rangeLabel, '25 Oct – 24 Nov');
    expect(period.rangeLabel.contains(' '), isFalse);
    expect(t.home.flowNet, 'Net');
    expect(
      t.plan.financialMonthOfferScheduled(start: t.plan.financialMonthOnDay(day: 25)),
      'Recurring scheduled. Start your financial month on day 25?',
    );
  });
}
