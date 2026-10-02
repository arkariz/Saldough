import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/recurring/domain/reminder_plan.dart';
import 'package:saldough/features/recurring/domain/reminder_scheduler.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Saluran Android pengingat rutin, terpisah dari pengingat catat
/// notifikasi (`CaptureReminders.kt`).
const _channelId = 'recurring_reminders';

/// Kategori iOS yang membawa aksi Catat.
const _iosCategory = 'recurring_record';

/// Id aksi Catat.
const _recordActionId = 'record';

/// [ReminderScheduler] di atas `flutter_local_notifications` (ADR-034
/// §3.8): penjadwalan tidak presisi (`inexactAllowWhileIdle`, tanpa izin
/// exact alarm), seluruh jadwal diganti tiap disusun ulang, dan aksi Catat
/// selalu membuka aplikasi (tanpa isolate latar).
///
/// Waktu dijadwalkan sebagai instan UTC dari jam lokal saat disusun; jadwal
/// disusun ulang tiap aplikasi dibuka, jadi pergantian zona waktu ikut
/// terkoreksi.
final class LocalNotificationReminderScheduler implements ReminderScheduler {
  /// Membuat [LocalNotificationReminderScheduler].
  LocalNotificationReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _responses = StreamController<ReminderResponse>.broadcast();
  Future<ReminderResponse?>? _initialized;

  static ReminderResponse _toResponse(NotificationResponse response) =>
      (payload: response.payload, recordAction: response.actionId == _recordActionId);

  @override
  Stream<ReminderResponse> get responses => _responses.stream;

  @override
  Future<ReminderResponse?> initialize() => _initialized ??= _initialize();

  Future<ReminderResponse?> _initialize() async {
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              _iosCategory,
              actions: [
                DarwinNotificationAction.plain(
                  _recordActionId,
                  t.recurring.recordAction,
                  options: {DarwinNotificationActionOption.foreground},
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: (response) => _responses.add(_toResponse(response)),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    return (launch?.didNotificationLaunchApp ?? false) && response != null ? _toResponse(response) : null;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    await initialize();
    await _plugin.cancelAll();
    for (final reminder in reminders) {
      final (title, body) = _texts(reminder);
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: title,
        body: body,
        payload: reminder.payload,
        scheduledDate: tz.TZDateTime.from(reminder.at.toUtc(), tz.UTC),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            t.recurring.reminderChannelName,
            channelDescription: t.recurring.reminderChannelDescription,
            actions: [
              if (reminder.canRecord)
                AndroidNotificationAction(_recordActionId, t.recurring.recordAction, showsUserInterface: true),
            ],
          ),
          iOS: DarwinNotificationDetails(categoryIdentifier: reminder.canRecord ? _iosCategory : null),
        ),
      );
    }
  }

  /// Judul dan isi: angka dan nama saja (PLAN_TAB_LAYOUT §4.9).
  static (String, String) _texts(PlannedReminder reminder) {
    final items = reminder.items;
    String line(({RecurringRule rule, DateTime date}) item) {
      final rule = item.rule;
      final name = rule.note.isEmpty ? t.record.repeat.fallbackName : rule.note;
      final amount = AppMoneyFormatter.format(rule.amount);
      return '$name ${rule.amountMode == RecurringAmountMode.estimated ? '≈' : ''}$amount';
    }

    return switch (reminder.kind) {
      ReminderKind.dueSoon => (
        t.recurring.reminderSoonTitle(n: items.single.rule.remindDaysBefore),
        line(items.single),
      ),
      ReminderKind.dueToday when items.length == 1 => (t.recurring.reminderTodayTitle, line(items.single)),
      ReminderKind.dueToday => (
        t.recurring.reminderTodayManyTitle(n: items.length),
        items.map(line).join(', '),
      ),
    };
  }
}
