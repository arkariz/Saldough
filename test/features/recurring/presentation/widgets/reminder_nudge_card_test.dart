import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/recurring/domain/reminder_scheduler.dart';
import 'package:saldough/features/recurring/domain/reminder_settings.dart';
import 'package:saldough/features/recurring/presentation/widgets/reminder_nudge_card.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

import '../../../../helpers/fake_feature_statuses.dart';

class _MockScheduler extends Mock implements ReminderScheduler {}

class _MockSettings extends Mock implements ReminderSettingsRepository {}

void main() {
  late GetIt container;
  late FakeFeatureStatuses statuses;
  late _MockScheduler scheduler;
  late _MockSettings settings;
  late FeatureStatusChanges changes;
  var notified = 0;

  setUp(() {
    final storage = InMemoryKeyValueStorage();
    statuses = FakeFeatureStatuses();
    scheduler = _MockScheduler();
    settings = _MockSettings();
    changes = FeatureStatusChanges();
    notified = 0;
    changes.stream.listen((_) => notified++);
    when(() => settings.isEnabled()).thenAnswer((_) async => right(false));
    when(() => settings.setEnabled(enabled: any(named: 'enabled'))).thenAnswer((_) async => right(unit));
    when(() => scheduler.replaceAll(any())).thenAnswer((_) async {});
    container = GetIt.asNewInstance()
      ..registerSingleton<FeatureStatuses>(statuses)
      ..registerSingleton<FeatureStatusChanges>(changes)
      ..registerSingleton<ReminderScheduler>(scheduler)
      ..registerSingleton<ReminderSettingsRepository>(settings)
      ..registerSingleton<RecurringRuleRepository>(RecurringRuleRepositoryImpl(storage: storage))
      ..registerSingleton<TransactionRepository>(TransactionRepositoryImpl(storage: storage));
  });

  Future<void> pump(WidgetTester tester, Widget Function(GetIt) child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(body: ListView(children: [child(container)])),
      ),
    );
    await tester.pumpAndSettle();
  }

  final nudge = find.byKey(const ValueKey('reminder-nudge'));
  final nudgeAction = find.byKey(const ValueKey('reminder-nudge-action'));

  group('kartu tombol pengingat', () {
    testWidgets('mati: judul, keterangan, dan Nyalakan; tanpa tombol tutup atau tunda', (tester) async {
      statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.off);
      await pump(tester, (c) => ReminderNudgeCard(container: c));

      expect(find.text(t.discovery.reminder.button), findsOneWidget);
      expect(find.text(t.discovery.reminder.body), findsOneWidget);
      expect(find.text(t.discovery.turnOn), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('izin hilang: Pengingat rutin / Izin belum diberikan / Izinkan', (tester) async {
      statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.permissionNeeded);
      await pump(tester, (c) => ReminderNudgeCard(container: c));

      expect(find.text(t.recurring.remindersTitle), findsOneWidget);
      expect(find.text(t.discovery.status.permissionNeeded), findsOneWidget);
      expect(find.text(t.discovery.allowAccess), findsOneWidget);
    });

    testWidgets('efektif atau tidak didukung: kartu hilang', (tester) async {
      statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.active);
      await pump(tester, (c) => ReminderNudgeCard(container: c));
      expect(nudge, findsNothing);
    });

    testWidgets('Nyalakan: izin diminta, sakelar menyala, jadwal disusun, status diberitahukan', (tester) async {
      statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.off);
      when(() => scheduler.requestPermission()).thenAnswer((_) async => true);
      await pump(tester, (c) => ReminderNudgeCard(container: c));

      statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.active);
      await tester.tap(nudgeAction);
      await tester.pumpAndSettle();

      verify(() => scheduler.requestPermission()).called(1);
      verify(() => settings.setEnabled(enabled: true)).called(1);
      verify(() => scheduler.replaceAll(any())).called(1);
      expect(notified, 1);
      expect(nudge, findsNothing);
    });

    testWidgets('izin ditolak: sakelar tidak berubah, snackbar, kartu tetap', (tester) async {
      statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.off);
      when(() => scheduler.requestPermission()).thenAnswer((_) async => false);
      await pump(tester, (c) => ReminderNudgeCard(container: c));

      await tester.tap(nudgeAction);
      await tester.pumpAndSettle();

      verifyNever(() => settings.setEnabled(enabled: any(named: 'enabled')));
      expect(find.text(t.recurring.remindersDenied), findsOneWidget);
      expect(nudge, findsOneWidget);
    });

    testWidgets('tanpa layanan terdaftar (uji, kontainer minimal): tidak membangun apa pun', (tester) async {
      await pump(tester, (_) => ReminderNudgeCard(container: GetIt.asNewInstance()));

      expect(nudge, findsNothing);
    });
  });

  group('catatan di sakelar per rutin', () {
    final note = find.byKey(const ValueKey('reminder-rule-note'));

    testWidgets('pengingat global mati: kalimat dan Nyalakan; menyalakan menghapus catatan', (tester) async {
      statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.off);
      when(() => scheduler.requestPermission()).thenAnswer((_) async => true);
      await pump(tester, (c) => ReminderRuleNote(container: c));
      expect(find.text(t.discovery.reminder.rowNote), findsOneWidget);
      expect(find.text(t.discovery.turnOn), findsOneWidget);

      statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.active);
      await tester.tap(find.byKey(const ValueKey('reminder-rule-note-action')));
      await tester.pumpAndSettle();

      verify(() => settings.setEnabled(enabled: true)).called(1);
      expect(note, findsNothing);
    });

    testWidgets('izin hilang: tombol Izinkan', (tester) async {
      statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.permissionNeeded);
      await pump(tester, (c) => ReminderRuleNote(container: c));

      expect(find.text(t.discovery.allowAccess), findsOneWidget);
    });

    testWidgets('efektif: tidak ada catatan', (tester) async {
      statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.active);
      await pump(tester, (c) => ReminderRuleNote(container: c));

      expect(note, findsNothing);
    });
  });
}
