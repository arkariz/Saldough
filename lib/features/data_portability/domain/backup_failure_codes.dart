import 'package:failures/failures.dart';

/// Kode galat cadangan dan pemulihan (ADR-040). Teks untuk pengguna ada di
/// i18n `dataPortability.error*`; kode ini juga menjadi `reason` analitik.
abstract final class BackupFailureCodes {
  /// Bukan cadangan Tanukonomy, rusak, atau checksum tidak cocok (R-1).
  static const invalid = FailureCode('BACKUP_INVALID');

  /// Dibuat versi Tanukonomy yang lebih baru (R-2).
  static const newer = FailureCode('BACKUP_NEWER');

  /// Isi tidak konsisten, mis. transaksi merujuk dompet yang tidak ada (R-3).
  static const inconsistent = FailureCode('BACKUP_INCONSISTENT');

  /// Ruang penyimpanan tidak cukup untuk menyiapkan pemulihan.
  static const space = FailureCode('BACKUP_SPACE');

  /// Belum ada transaksi untuk diekspor.
  static const emptyExport = FailureCode('EXPORT_EMPTY');

  /// Pengguna membatalkan ekspor yang sedang disiapkan; bukan galat.
  static const cancelled = FailureCode('EXPORT_CANCELLED');
}

/// Galat dari kodek dan validator cadangan. Dilempar di lapisan data dan
/// dipetakan ke `Failure` oleh use case (`RepositoryGuard.mapCustomError`).
final class BackupException implements Exception {
  /// Membuat [BackupException].
  const BackupException(this.code, this.message);

  /// Salah satu [BackupFailureCodes].
  final FailureCode code;

  /// Diagnostik untuk pengembang, bukan untuk pengguna.
  final String message;

  @override
  String toString() => 'BackupException($code): $message';
}
