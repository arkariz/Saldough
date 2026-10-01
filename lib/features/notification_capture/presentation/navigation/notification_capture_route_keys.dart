import 'package:navigation/navigation.dart';

// Satu-satunya berkas fitur `notification_capture` yang boleh diimpor fitur
// lain (ADR-0004, ADR-030 §3.3, ADR-033 §3.3).

/// Kunci rute fitur `notification_capture` (ADR-032). Android saja.
abstract final class NotificationCaptureRouteKeys {
  /// Setelan Catat dari notifikasi, dari layar Akun.
  static const settings = RouteKey<EmptyInput>('notificationCapture.settings');

  /// Kotak masuk (ADR-032 §3.6), dari kartu Beranda dan snackbar shell.
  static const inbox = RouteKey<EmptyInput>('notificationCapture.inbox');
}
