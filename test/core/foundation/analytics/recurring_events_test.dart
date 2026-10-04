import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';

/// Peristiwa rutin R1 dan R3 (T-17.8): nama tetap, tanpa nominal.
void main() {
  test('nama dan parameter', () {
    expect(RecurringEvents.created('record'), const AnalyticsEvent('recurring_created', {'source': 'record'}));
    expect(
      RecurringEvents.occurrenceRecorded('record_all', count: 3),
      const AnalyticsEvent('occurrence_recorded', {'method': 'record_all', 'count': 3}),
    );
    expect(RecurringEvents.occurrenceSkipped.name, 'occurrence_skipped');
    expect(RecurringEvents.occurrenceLinked.parameters, {'by': 'user'});
    expect(RecurringEvents.unseenNotYet.name, 'occurrence_unseen_action');
    expect(RecurringEvents.idleAction('keep').parameters, {'action': 'keep'});
    expect(
      RecurringEvents.autoRecordToggled(on: true, where: 'form'),
      const AnalyticsEvent('auto_record_toggled', {'on': 'true', 'where': 'form'}),
    );
    expect(RecurringEvents.priceIncreaseAction('update').name, 'price_increase_action');
    expect(RecurringEvents.suggestionAction('dismiss').name, 'recurring_suggestion_action');
    expect(PlanEvents.autoRecorded(2).parameters, {'count': 2});
    expect(RecurringEvents.occurrenceLinkedAuto.parameters, {'by': 'auto'});
    expect(RecurringEvents.occurrenceUnlinked.name, 'occurrence_unlinked');
    expect(PlanEvents.planSegmentViewed('recurring'), const AnalyticsEvent('plan_viewed', {'segment': 'recurring'}));
  });

  test('tidak ada parameter bernominal', () {
    final events = [
      RecurringEvents.created('record'),
      RecurringEvents.occurrenceRecorded('one_tap'),
      RecurringEvents.occurrenceSkipped,
      RecurringEvents.occurrenceLinked,
      RecurringEvents.unseenNotYet,
      RecurringEvents.idleAction('end'),
      RecurringEvents.autoRecordToggled(on: false, where: 'detail'),
      RecurringEvents.priceIncreaseAction('keep'),
      RecurringEvents.suggestionAction('accept'),
      PlanEvents.autoRecorded(1),
      PlanEvents.autoRecordUndone,
    ];
    for (final e in events) {
      expect(e.parameters.keys.where((k) => k.contains('amount') || k.contains('minor')), isEmpty, reason: e.name);
    }
  });
}
