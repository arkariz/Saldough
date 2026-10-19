import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/app/discovery/app_feature_statuses.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/recurring/domain/reminder_scheduler.dart';
import 'package:saldough/features/recurring/domain/reminder_settings.dart';

class _MockGateway extends Mock implements NotificationCaptureGateway {}

class _MockStore extends Mock implements NotificationCaptureStore {}

class _MockReminderSettings extends Mock implements ReminderSettingsRepository {}

class _MockScheduler extends Mock implements ReminderScheduler {}

void main() {
  late _MockGateway gateway;
  late _MockStore store;
  late _MockReminderSettings reminderSettings;
  late _MockScheduler scheduler;
  late FeatureStatusChanges changes;
  late AppFeatureStatuses statuses;

  const bri = NotificationSource(packageName: 'id.co.bri.brimo', appLabel: 'BRImo');
  const gopay = NotificationSource(packageName: 'com.gojek.gopay', appLabel: 'GoPay');

  void stubSettings(NotificationCaptureSettings settings) {
    when(() => store.loadSettings()).thenAnswer((_) async => right(settings));
  }

  setUp(() {
    gateway = _MockGateway();
    store = _MockStore();
    reminderSettings = _MockReminderSettings();
    scheduler = _MockScheduler();
    changes = FeatureStatusChanges();
    statuses = AppFeatureStatuses(
      captureGateway: gateway,
      captureStore: store,
      reminderSettings: reminderSettings,
      reminderScheduler: scheduler,
      changesSource: changes,
    );
    when(() => gateway.isSupported).thenReturn(true);
    when(() => gateway.isAccessGranted()).thenAnswer((_) async => true);
  });

  group('Catat dari notifikasi', () {
    Future<FeatureStatus> read() => statuses.read(DiscoveredFeature.notification);

    test('iOS: platform tidak mendukung, tanpa pintu', () async {
      when(() => gateway.isSupported).thenReturn(false);

      final status = await read();

      expect(status, FeatureStatus.unsupported);
      expect(status.isSupported, isFalse);
      verifyNever(() => store.loadSettings());
    });

    test('belum ada aplikasi sumber: belum disetel', () async {
      stubSettings(const NotificationCaptureSettings(enabled: true));

      final status = await read();

      expect(status.state, FeatureState.unset);
      expect(status.isEffective, isFalse);
    });

    test('semua sumber dihapus kembali ke belum disetel walau sakelar nyala', () async {
      stubSettings(const NotificationCaptureSettings(enabled: true, sources: [bri]));
      expect((await read()).state, FeatureState.active);

      stubSettings(const NotificationCaptureSettings(enabled: true));
      expect((await read()).state, FeatureState.unset);
    });

    test('sumber yang semuanya dinonaktifkan dihitung belum disetel', () async {
      stubSettings(
        const NotificationCaptureSettings(
          enabled: true,
          sources: [NotificationSource(packageName: 'a', appLabel: 'A', enabled: false)],
        ),
      );

      expect((await read()).state, FeatureState.unset);
    });

    test('sakelar mati dengan sumber aktif: mati, jumlah tetap terbaca', () async {
      stubSettings(const NotificationCaptureSettings(sources: [bri, gopay]));

      final status = await read();

      expect(status, const FeatureStatus(FeatureState.off, activeCount: 2));
      expect(status.isEffective, isFalse);
    });

    test('akses notifikasi dicabut di sistem: butuh izin', () async {
      stubSettings(const NotificationCaptureSettings(enabled: true, sources: [bri]));
      when(() => gateway.isAccessGranted()).thenAnswer((_) async => false);

      expect(await read(), const FeatureStatus(FeatureState.permissionNeeded, activeCount: 1));
    });

    test('nyala dan izin ada: aktif dengan jumlah aplikasi', () async {
      stubSettings(const NotificationCaptureSettings(enabled: true, sources: [bri, gopay]));

      final status = await read();

      expect(status, const FeatureStatus(FeatureState.active, activeCount: 2));
      expect(status.isEffective, isTrue);
    });

    test('setelan gagal dibaca dianggap belum disetel, tanpa melempar', () async {
      when(() => store.loadSettings()).thenAnswer((_) async => left(const SystemFailure(code: FailureCode.unknown, message: 'x')));

      expect((await read()).state, FeatureState.unset);
    });
  });

  group('Pengingat rutin', () {
    Future<FeatureStatus> read() => statuses.read(DiscoveredFeature.reminder);

    test('sakelar mati: mati, izin tidak dicek', () async {
      when(() => reminderSettings.isEnabled()).thenAnswer((_) async => right(false));

      expect((await read()).state, FeatureState.off);
      verifyNever(() => scheduler.hasPermission());
    });

    test('nyala tetapi izin notifikasi dicabut: butuh izin', () async {
      when(() => reminderSettings.isEnabled()).thenAnswer((_) async => right(true));
      when(() => scheduler.hasPermission()).thenAnswer((_) async => false);

      expect((await read()).state, FeatureState.permissionNeeded);
    });

    test('nyala dan izin ada: aktif', () async {
      when(() => reminderSettings.isEnabled()).thenAnswer((_) async => right(true));
      when(() => scheduler.hasPermission()).thenAnswer((_) async => true);

      expect((await read()).isEffective, isTrue);
    });

    test('sakelar gagal dibaca dianggap mati', () async {
      when(() => reminderSettings.isEnabled()).thenAnswer((_) async => left(const SystemFailure(code: FailureCode.unknown, message: 'x')));

      expect((await read()).state, FeatureState.off);
    });
  });

  test('changes meneruskan sinyal penulis setelan', () async {
    final events = <void>[];
    final sub = statuses.changes.listen(events.add);

    changes.notify();
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    await sub.cancel();
  });
}
