import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/record/domain/capture/notification/captured_notification.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_capture_gateway.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_source.dart';

/// [NotificationCaptureGateway] Android lewat kanal
/// `tanukonomy/notification_capture` (`NotificationCapturePlugin.kt`).
final class MethodChannelNotificationCaptureGateway with RepositoryGuard implements NotificationCaptureGateway {
  /// Membuat [MethodChannelNotificationCaptureGateway].
  MethodChannelNotificationCaptureGateway({
    this._methods = const MethodChannel(channelName),
    this._capturedEvents = const EventChannel('$channelName/captured'),
    this._tapEvents = const EventChannel('$channelName/taps'),
  });

  /// Nama kanal metode.
  static const channelName = 'tanukonomy/notification_capture';

  final MethodChannel _methods;
  final EventChannel _capturedEvents;
  final EventChannel _tapEvents;
  Stream<void>? _capturedStream;
  Stream<String>? _taps;

  @override
  bool get isSupported => true;

  @override
  Future<bool> isAccessGranted() async => await _methods.invokeMethod<bool>('isAccessGranted') ?? false;

  @override
  Future<void> openAccessSettings() => _methods.invokeMethod<void>('openAccessSettings');

  @override
  Future<bool> canPostReminders() async => await _methods.invokeMethod<bool>('canPostReminders') ?? false;

  @override
  Future<bool> requestReminderPermission() async =>
      await _methods.invokeMethod<bool>('requestReminderPermission') ?? false;

  @override
  Future<Either<Failure, Unit>> configure({
    required bool enabled,
    required List<NotificationSource> sources,
    required bool remindWhenClosed,
    required ReminderTexts texts,
  }) => guardVoid(
    () => _methods.invokeMethod<void>('configure', {
      'enabled': enabled,
      'remindWhenClosed': remindWhenClosed,
      'channelName': texts.channelName,
      'capturedTitle': texts.capturedTitle,
      'capturedBody': texts.capturedBody,
      'sources': [
        for (final s in sources)
          if (s.enabled) {'packageName': s.packageName, 'label': s.appLabel, 'keywords': s.keywords},
      ],
    }),
  );

  @override
  Future<Either<Failure, List<CapturedNotification>>> pending() => guard(() async {
    final raw = await _methods.invokeListMethod<Map<Object?, Object?>>('pending') ?? const [];
    return [for (final item in raw) _toCaptured(item)];
  });

  @override
  Future<Either<Failure, Unit>> acknowledge(List<String> ids) =>
      guardVoid(() => _methods.invokeMethod<void>('acknowledge', {'ids': ids}));

  @override
  Stream<void> get captured => _capturedStream ??= _capturedEvents.receiveBroadcastStream().map((_) {});

  @override
  Stream<String> get reminderTaps => _taps ??= _tapEvents.receiveBroadcastStream().map((id) => id as String);

  @override
  Future<String?> takeLaunchReminderTap() => _methods.invokeMethod<String>('takeLaunchReminderTap');

  @override
  Future<void> showReminder({
    required String captureId,
    required String title,
    required String body,
    Uint8List? icon,
  }) => _methods.invokeMethod<void>('showReminder', {
    'captureId': captureId,
    'title': title,
    'body': body,
    'icon': ?icon,
  });

  @override
  Future<Either<Failure, List<InstalledApp>>> installedApps() => guard(() async {
    final raw = await _methods.invokeListMethod<Map<Object?, Object?>>('installedApps') ?? const [];
    return [
      for (final app in raw)
        InstalledApp(
          packageName: app['packageName']! as String,
          label: app['label'] as String? ?? app['packageName']! as String,
          icon: app['icon'] as Uint8List?,
        ),
    ];
  });

  @override
  Future<List<CapturedNotification>> debugSamples() async {
    try {
      final raw = await _methods.invokeListMethod<Map<Object?, Object?>>('debugSamples') ?? const [];
      return [for (final item in raw) _toCaptured(item)];
    } on PlatformException {
      return const [];
    }
  }

  static CapturedNotification _toCaptured(Map<Object?, Object?> item) => CapturedNotification(
    id: item['id']! as String,
    packageName: item['packageName']! as String,
    title: item['title'] as String? ?? '',
    body: item['body'] as String? ?? '',
    postedAt: DateTime.fromMillisecondsSinceEpoch((item['postedAt']! as num).toInt()),
    icon: switch (item['icon']) {
      final Uint8List png when png.isNotEmpty => png,
      _ => null,
    },
  );
}

/// [NotificationCaptureGateway] untuk platform yang tidak mengizinkan
/// membaca notifikasi aplikasi lain (iOS) dan uji.
final class UnsupportedNotificationCaptureGateway implements NotificationCaptureGateway {
  /// Membuat [UnsupportedNotificationCaptureGateway].
  const UnsupportedNotificationCaptureGateway();

  @override
  bool get isSupported => false;

  @override
  Future<bool> isAccessGranted() async => false;

  @override
  Future<void> openAccessSettings() async {}

  @override
  Future<bool> canPostReminders() async => false;

  @override
  Future<bool> requestReminderPermission() async => false;

  @override
  Future<Either<Failure, Unit>> configure({
    required bool enabled,
    required List<NotificationSource> sources,
    required bool remindWhenClosed,
    required ReminderTexts texts,
  }) async => right(unit);

  @override
  Future<Either<Failure, List<CapturedNotification>>> pending() async => right(const []);

  @override
  Future<Either<Failure, Unit>> acknowledge(List<String> ids) async => right(unit);

  @override
  Stream<void> get captured => const Stream.empty();

  @override
  Stream<String> get reminderTaps => const Stream.empty();

  @override
  Future<String?> takeLaunchReminderTap() async => null;

  @override
  Future<void> showReminder({
    required String captureId,
    required String title,
    required String body,
    Uint8List? icon,
  }) async {}

  @override
  Future<Either<Failure, List<InstalledApp>>> installedApps() async => right(const []);

  @override
  Future<List<CapturedNotification>> debugSamples() async => const [];
}
