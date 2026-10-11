import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';

/// Peristiwa periode keuangan (T-18.11, FINANCIAL_PERIOD §8A): nama dan
/// parameter persis tabel, tanpa nominal dan tanpa tanggal.
void main() {
  test('nama dan parameter', () {
    expect(
      PeriodEvents.sheetOpened('plan'),
      const AnalyticsEvent('financial_month_sheet_opened', {'source': 'plan'}),
    );
    expect(
      PeriodEvents.changed(source: 'offer', day: 'last', transitionDays: 0, movedBudgets: 2, keptBudgets: 1),
      const AnalyticsEvent('financial_month_changed', {
        'source': 'offer',
        'day': 'last',
        'transition_days': 0,
        'moved_budgets': 2,
        'kept_budgets': 1,
      }),
    );
    expect(PeriodEvents.offer('dismissed'), const AnalyticsEvent('financial_month_offer', {'action': 'dismissed'}));
  });

  test('recurrence_date_gap: ember selisih hari 0, 3, 7, 8, 15, ke arah mana pun, tanpa tanggal', () {
    final occurrence = DateTime(2026, 10, 25);
    String bucket(int days) =>
        PeriodEvents.recurrenceDateGap(DateTime(2026, 10, 25 + days, 21), occurrence).parameters['bucket']! as String;
    expect(bucket(0), '0');
    expect(bucket(1), '1-3');
    expect(bucket(3), '1-3');
    expect(bucket(-3), '1-3');
    expect(bucket(4), '4-7');
    expect(bucket(7), '4-7');
    expect(bucket(8), '8-14');
    expect(bucket(14), '8-14');
    expect(bucket(15), '15+');
    expect(bucket(-15), '15+');
    // Melewati batas bulan dan pergantian jam musim panas tidak menggeser hari.
    expect(PeriodEvents.gapBucket(DateTime(2026, 11, 1, 0, 30), DateTime(2026, 10, 31, 23)), '1-3');
    final event = PeriodEvents.recurrenceDateGap(occurrence, occurrence);
    expect(event.name, 'recurrence_date_gap');
    expect(event.parameters.keys, ['bucket']);
  });
}
