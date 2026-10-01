import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/record/domain/capture/notification/captured_notification.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_capture_gateway.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_source.dart';

/// [NotificationCaptureGateway] palsu untuk uji Catat dari notifikasi.
final class FakeNotificationCaptureGateway implements NotificationCaptureGateway {
  /// Antrean native.
  List<CapturedNotification> queue = [];

  /// Id yang di-ack.
  final acked = <String>[];

  /// Ack gagal (simulasi crash sebelum ack).
  bool failAck = false;

  /// Akses sistem.
  bool accessGranted = false;

  /// Izin pengingat sekarang, dan hasil permintaannya.
  bool remindersAllowed = false;

  /// Hasil `requestReminderPermission`.
  bool grantReminders = false;

  /// Setelan akses dibuka.
  int accessSettingsOpened = 0;

  /// Berapa kali izin pengingat diminta.
  int reminderPermissionRequests = 0;

  /// Argumen `configure` terakhir.
  List<NotificationSource>? configuredSources;

  /// Mode pengingat terakhir.
  bool? configuredRemind;

  /// Aplikasi terpasang.
  List<InstalledApp> apps = const [];

  @override
  bool get isSupported => true;

  @override
  Future<Either<Failure, List<CapturedNotification>>> pending() async => right([...queue]);

  @override
  Future<Either<Failure, Unit>> acknowledge(List<String> ids) async {
    if (failAck) return left(const SystemFailure(code: FailureCode.unknown, message: 'ack'));
    acked.addAll(ids);
    queue.removeWhere((n) => ids.contains(n.id));
    return right(unit);
  }

  @override
  Stream<void> get captured => const Stream.empty();

  @override
  Stream<String> get reminderTaps => const Stream.empty();

  @override
  Future<String?> takeLaunchReminderTap() async => null;

  @override
  Future<bool> isAccessGranted() async => accessGranted;

  @override
  Future<void> openAccessSettings() async => accessSettingsOpened++;

  @override
  Future<bool> canPostReminders() async => remindersAllowed;

  @override
  Future<bool> requestReminderPermission() async {
    reminderPermissionRequests++;
    return remindersAllowed = grantReminders;
  }

  @override
  Future<Either<Failure, Unit>> configure({
    required bool enabled,
    required List<NotificationSource> sources,
    required bool remindWhenClosed,
    required ReminderTexts texts,
  }) async {
    configuredSources = sources;
    configuredRemind = remindWhenClosed;
    return right(unit);
  }

  @override
  Future<void> showReminder({
    required String captureId,
    required String title,
    required String body,
    Uint8List? icon,
  }) async {}

  @override
  Future<Either<Failure, List<InstalledApp>>> installedApps() async => right(apps);

  @override
  Future<List<CapturedNotification>> debugSamples() async => const [];
}
