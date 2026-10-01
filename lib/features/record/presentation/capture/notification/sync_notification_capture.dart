import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_capture_gateway.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_capture_settings.dart';

/// Mengirim [settings] ke layanan native, dengan teks pengingat generik
/// dalam bahasa aplikasi (ADR-028; native tidak tahu bahasa pilihan
/// pengguna). Dipanggil setiap setelan berubah dan saat aplikasi dibuka
/// (bahasa bisa sudah berganti).
Future<void> syncNotificationCapture(NotificationCaptureGateway gateway, NotificationCaptureSettings settings) async {
  if (!gateway.isSupported) return;
  final texts = t.notificationCapture;
  await gateway.configure(
    enabled: settings.enabled,
    sources: settings.sources,
    remindWhenClosed: settings.delivery == NotificationDelivery.reminderAndInbox,
    texts: ReminderTexts(
      channelName: texts.reminderChannel,
      capturedTitle: texts.reminderCapturedTitle,
      capturedBody: texts.reminderCapturedBody,
    ),
  );
}
