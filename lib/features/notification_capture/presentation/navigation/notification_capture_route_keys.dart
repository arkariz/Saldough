import 'package:navigation/navigation.dart';

// Satu-satunya berkas fitur `notification_capture` yang boleh diimpor fitur
// lain (ADR-0004, ADR-030 §3.3, ADR-033 §3.3).

/// Input [NotificationCaptureRouteKeys.teachPattern].
final class TeachPatternInput extends RouteInput {
  /// Membuat [TeachPatternInput].
  const TeachPatternInput({required this.entryId});

  /// Tangkapan kotak masuk yang teksnya jadi contoh pola.
  final String entryId;
}

/// Kunci rute fitur `notification_capture` (ADR-032). Android saja.
abstract final class NotificationCaptureRouteKeys {
  /// Setelan Catat dari notifikasi, dari layar Akun.
  static const settings = RouteKey<EmptyInput>('notificationCapture.settings');

  /// Kotak masuk (ADR-032 §3.6), dari kartu Beranda dan snackbar shell.
  static const inbox = RouteKey<EmptyInput>('notificationCapture.inbox');

  /// Mulai cepat penyetelan pertama (FEATURE_DISCOVERY §5.1), dari baris
  /// pintu di Beranda. Hasilnya `true` bila fitur akhirnya aktif.
  static const quickStart = RouteKey<EmptyInput>('notificationCapture.quickStart');

  /// Kotak masuk yang langsung membuka pembuat pola untuk satu tangkapan
  /// (Ajari pola di kartu Beranda, FEATURE_DISCOVERY P-8).
  static const teachPattern = RouteKey<TeachPatternInput>('notificationCapture.teachPattern');
}
