import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';

/// Aplikasi terpasang yang bisa dipilih sebagai sumber.
final class InstalledApp extends Equatable {
  /// Membuat [InstalledApp].
  const InstalledApp({required this.packageName, required this.label, this.icon});

  /// Nama paket.
  final String packageName;

  /// Nama aplikasi.
  final String label;

  /// Ikon PNG kecil, atau `null`.
  final List<int>? icon;

  @override
  List<Object?> get props => [packageName, label];
}

/// Teks pengingat generik native, dalam bahasa aplikasi (ADR-028), karena
/// layanan native tidak tahu bahasa yang dipilih pengguna.
final class ReminderTexts extends Equatable {
  /// Membuat [ReminderTexts].
  const ReminderTexts({required this.channelName, required this.capturedTitle, required this.capturedBody});

  /// Nama kanal notifikasi di setelan Android.
  final String channelName;

  /// Judul pengingat generik; `{app}` diganti nama aplikasi.
  final String capturedTitle;

  /// Isi pengingat generik.
  final String capturedBody;

  @override
  List<Object?> get props => [channelName, capturedTitle, capturedBody];
}

/// Pintu ke layanan notifikasi platform (ADR-032 §3.1). Implementasi Android
/// lewat kanal Flutter; platform lain tidak didukung.
abstract interface class NotificationCaptureGateway {
  /// Platform mendukung fitur ini.
  bool get isSupported;

  /// Pengguna sudah memberi akses notifikasi di setelan sistem.
  Future<bool> isAccessGranted();

  /// Membuka setelan akses notifikasi sistem.
  Future<void> openAccessSettings();

  /// Izin memunculkan notifikasi (Android 13+) sudah ada.
  Future<bool> canPostReminders();

  /// Meminta izin memunculkan notifikasi; hasilnya diberikan atau tidak.
  Future<bool> requestReminderPermission();

  /// Mengirim sumber aktif, kata kunci, dan teks pengingat ke layanan native.
  /// [remindWhenClosed] = mode pengingat.
  Future<Either<Failure, Unit>> configure({
    required bool enabled,
    required List<NotificationSource> sources,
    required bool remindWhenClosed,
    required ReminderTexts texts,
  });

  /// Tangkapan yang menunggu di antrean native.
  Future<Either<Failure, List<CapturedNotification>>> pending();

  /// Menghapus tangkapan yang sudah diproses dari antrean native.
  Future<Either<Failure, Unit>> acknowledge(List<String> ids);

  /// Tangkapan baru selagi mesin Flutter hidup.
  Stream<void> get captured;

  /// Identitas tangkapan dari ketukan pengingat (termasuk yang membuka
  /// aplikasi).
  Stream<String> get reminderTaps;

  /// Ketukan pengingat yang membuka aplikasi, sekali, atau `null`.
  Future<String?> takeLaunchReminderTap();

  /// Memunculkan pengingat untuk satu tangkapan; [icon] (PNG) jadi ikon
  /// besarnya.
  Future<void> showReminder({
    required String captureId,
    required String title,
    required String body,
    Uint8List? icon,
  });

  /// Daftar aplikasi peluncur terpasang.
  Future<Either<Failure, List<InstalledApp>>> installedApps();

  /// Build debug: teks mentah terakhir dari paket terdaftar, sebelum saringan
  /// kata kunci (ADR-032 §3.6). Kosong di build rilis.
  Future<List<CapturedNotification>> debugSamples();
}
