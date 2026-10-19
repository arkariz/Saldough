import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/notification_inbox_card.dart';
import 'package:saldough/features/recurring/domain/reminder_scheduler.dart';
import 'package:saldough/features/recurring/domain/reminder_settings.dart';
import 'package:saldough/features/recurring/presentation/widgets/reminder_nudge_card.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

import '../helpers/fake_feature_statuses.dart';

class _MockScheduler extends Mock implements ReminderScheduler {}

class _MockSettings extends Mock implements ReminderSettingsRepository {}

/// Tur Beranda untuk pintu permanen Fase 21 (T-21.6, ADR-021): tiap langkah
/// disorot sekali saat kartunya pertama tampil, dan hanya bila kartunya ada.
void main() {
  late GetIt container;
  late FakeFeatureStatuses statuses;
  late TutorialProgressRepositoryImpl tutorials;

  setUp(() async {
    final storage = InMemoryKeyValueStorage();
    statuses = FakeFeatureStatuses();
    tutorials = TutorialProgressRepositoryImpl(storage: storage);
    // Langkah Beranda lain sudah dilihat: yang diuji hanya langkah baru.
    await tutorials.markStepsSeen([
      for (final step in tourSteps[TourId.home]!)
        if (step != SpotlightKey.homeNotification && step != SpotlightKey.homeReminder) step,
    ]);
    container = GetIt.asNewInstance()
      ..registerSingleton<FeatureStatuses>(statuses)
      ..registerSingleton<FeatureStatusChanges>(FeatureStatusChanges())
      ..registerSingleton<NotificationCaptureStore>(NotificationCaptureStoreImpl(storage: storage))
      ..registerSingleton<CaptureInboxChanges>(CaptureInboxChanges())
      ..registerSingleton<ReminderScheduler>(_MockScheduler())
      ..registerSingleton<ReminderSettingsRepository>(_MockSettings())
      ..registerSingleton<RecurringRuleRepository>(RecurringRuleRepositoryImpl(storage: storage))
      ..registerSingleton<TransactionRepository>(TransactionRepositoryImpl(storage: storage));
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
          theme: PixelTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: SpotlightHost(repository: tutorials, child: child!),
          ),
          home: Scaffold(
            body: ListView(
              children: [
                NotificationInboxCard(container: container),
                ReminderNudgeCard(container: container, spotlight: true),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder step(int current, int total, String title, String body) =>
      find.bySemanticsLabel(t.tour.stepSemantics(current: current, total: total, title: title, body: body));

  Future<bool> seen(SpotlightKey key) async =>
      (await tutorials.load()).getOrElse((_) => throw StateError('')).hasSeen(key);

  testWidgets('kartu Kotak masuk notifikasi disorot sekali saat pertama tampil', (tester) async {
    statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.unset);
    await pump(tester);

    expect(step(1, 1, t.tour.homeNotificationTitle, t.tour.homeNotificationBody), findsOneWidget);
    await tester.tap(find.text(t.tour.doneAction).last);
    await tester.pumpAndSettle();
    expect(await seen(SpotlightKey.homeNotification), isTrue);

    await pump(tester);
    expect(find.text(t.tour.doneAction), findsNothing);
  });

  testWidgets('kartu pengingat disorot sekali saat pertama tampil', (tester) async {
    statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.off);
    await pump(tester);

    expect(step(1, 1, t.tour.homeReminderTitle, t.tour.homeReminderBody), findsOneWidget);
    await tester.tap(find.text(t.tour.doneAction).last);
    await tester.pumpAndSettle();
    expect(await seen(SpotlightKey.homeReminder), isTrue);
  });

  testWidgets('kartu yang tidak ada tidak disorot: pengingat efektif dan iOS', (tester) async {
    statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.active);
    await pump(tester);

    expect(find.text(t.tour.doneAction), findsNothing);
    expect(find.text(t.tour.nextAction), findsNothing);
    expect(await seen(SpotlightKey.homeNotification), isFalse);
    expect(await seen(SpotlightKey.homeReminder), isFalse);
  });

  testWidgets('pengguna lama yang menamatkan tur Beranda tetap melihat dua langkah baru sekali', (tester) async {
    await tutorials.markStepsSeen(
      tourSteps[TourId.home]!.where((k) => k != SpotlightKey.homeNotification && k != SpotlightKey.homeReminder),
    );
    statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.unset);
    statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.off);
    await pump(tester);

    expect(find.byKey(const ValueKey('notification-inbox-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('reminder-nudge')), findsOneWidget);
    expect(
      find.text(t.tour.nextAction).evaluate().length + find.text(t.tour.doneAction).evaluate().length,
      greaterThan(0),
    );
  });
}
