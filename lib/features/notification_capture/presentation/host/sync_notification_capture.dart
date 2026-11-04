import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';

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
    // Bawaan: native menyalakan notifikasi hanya bila Plus (salinan status di CapturePlan).
    autoNotify: settings.delivery == NotificationDelivery.automatic,
    saveSamples: settings.saveSamples,
    texts: ReminderTexts(
      channelName: texts.reminderChannel,
      capturedTitle: texts.reminderCapturedTitle,
      capturedBody: texts.reminderCapturedBody,
      actionRecord: texts.recordAction,
      actionDismiss: texts.dismissAction,
      actionUndo: texts.undoAction,
      recordedTitle: texts.actionableRecordedTitle,
      recordedBody: texts.actionableRecordedBody,
      undoneTitle: texts.actionableUndoneTitle,
      undoneBody: texts.actionableUndoneBody,
      groupSummary: texts.actionableGroupSummary(count: '{count}'),
      recordAll: texts.actionableRecordAll,
      recordedMany: texts.actionableRecordedMany(count: '{count}'),
    ),
  );
}
