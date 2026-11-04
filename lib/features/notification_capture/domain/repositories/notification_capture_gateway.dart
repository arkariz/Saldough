import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_journal_record.dart';
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
  const ReminderTexts({
    required this.channelName,
    required this.capturedTitle,
    required this.capturedBody,
    this.actionRecord = '',
    this.actionDismiss = '',
    this.actionUndo = '',
    this.recordedTitle = '',
    this.recordedBody = '',
    this.undoneTitle = '',
    this.undoneBody = '',
    this.groupSummary = '',
    this.recordAll = '',
    this.recordedMany = '',
  });

  /// Nama kanal notifikasi di setelan Android.
  final String channelName;

  /// Judul pengingat generik; `{app}` diganti nama aplikasi.
  final String capturedTitle;

  /// Isi pengingat generik.
  final String capturedBody;

  /// Tombol Catat pada notifikasi bertindak (ADR-044 §3.5).
  final String actionRecord;

  /// Tombol Abaikan.
  final String actionDismiss;

  /// Tombol Batalkan pada hasil.
  final String actionUndo;

  /// Judul hasil Catat.
  final String recordedTitle;

  /// Isi hasil Catat.
  final String recordedBody;

  /// Judul hasil Batalkan.
  final String undoneTitle;

  /// Isi hasil Batalkan.
  final String undoneBody;

  /// Ringkasan kelompok; `{count}` diganti jumlah.
  final String groupSummary;

  /// Tombol Catat semua pada ringkasan kelompok.
  final String recordAll;

  /// Judul hasil Catat semua; `{count}` diganti jumlah.
  final String recordedMany;

  @override
  List<Object?> get props => [
    channelName,
    capturedTitle,
    capturedBody,
    actionRecord,
    actionDismiss,
    actionUndo,
    recordedTitle,
    recordedBody,
    undoneTitle,
    undoneBody,
    groupSummary,
    recordAll,
    recordedMany,
  ];
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
  /// [remindWhenClosed] = notifikasi dinyalakan pengguna; [autoNotify] =
  /// bawaan (ADR-044 §3.5): native menyalakannya hanya bila paket Plus.
  Future<Either<Failure, Unit>> configure({
    required bool enabled,
    required List<NotificationSource> sources,
    required bool remindWhenClosed,
    required ReminderTexts texts,
    bool saveSamples = false,
    bool autoNotify = false,
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

  /// Contoh notifikasi aplikasi [packageName] yang disimpan native bila
  /// `saveSamples` menyala (ADR-042 §3.2), terbaru lebih dulu.
  Future<List<CapturedNotification>> samples(String packageName);

  /// Menghapus contoh [packageName], atau semuanya bila `null`.
  Future<void> clearSamples({String? packageName});

  /// Entri jurnal notifikasi bertindak yang menunggu diterapkan (ADR-044 §3.5).
  Future<List<CaptureJournalRecord>> journal();

  /// Membuang entri jurnal [ids] yang sudah diterapkan.
  Future<void> acknowledgeJournal(List<String> ids);

  /// Membersihkan notifikasi bertindak yang masih tampil: aplikasi dibuka dan
  /// tangkapannya kini kartu di kotak masuk.
  Future<void> cancelActionable();

  /// Menyalin status Plus ke native untuk mesin tanpa layar. [until]: batas
  /// akhir bila diketahui; tanpa batas, salinan basi setelah 14 hari.
  Future<void> syncPlan({required bool isPlus, DateTime? until});
}
