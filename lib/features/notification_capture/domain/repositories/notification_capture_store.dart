import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';

/// Penyimpanan Catat dari notifikasi (ADR-032): setelan, pola pengguna, kotak
/// masuk, log otomatis, dan id tangkapan yang sudah diproses.
abstract interface class NotificationCaptureStore {
  /// Setelan; bawaan bila belum pernah disimpan.
  Future<Either<Failure, NotificationCaptureSettings>> loadSettings();

  /// Menyimpan setelan.
  Future<Either<Failure, Unit>> saveSettings(NotificationCaptureSettings settings);

  /// Pola buatan pengguna.
  Future<Either<Failure, List<NotificationPattern>>> loadPatterns();

  /// Menyimpan pola buatan pengguna.
  Future<Either<Failure, Unit>> savePatterns(List<NotificationPattern> patterns);

  /// Isi kotak masuk.
  Future<Either<Failure, List<CaptureInboxEntry>>> loadInbox();

  /// Menyimpan kotak masuk.
  Future<Either<Failure, Unit>> saveInbox(List<CaptureInboxEntry> entries);

  /// Log tercatat otomatis.
  Future<Either<Failure, List<AutoRecordedEntry>>> loadAutoRecorded();

  /// Menyimpan log tercatat otomatis.
  Future<Either<Failure, Unit>> saveAutoRecorded(List<AutoRecordedEntry> entries);

  /// Id tangkapan yang sudah diproses → waktu diproses.
  Future<Either<Failure, Map<String, DateTime>>> loadProcessedIds();

  /// Menyimpan id tangkapan yang sudah diproses.
  Future<Either<Failure, Unit>> saveProcessedIds(Map<String, DateTime> ids);
}
