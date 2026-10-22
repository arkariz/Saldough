import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/data_portability/domain/backup_models.dart';
import 'package:saldough/features/data_portability/domain/backup_summary.dart';
import 'package:saldough/features/data_portability/domain/export_models.dart';

/// Membuat cadangan seluruh data (FR-DAT-002, EXPORT_BACKUP §6). Implementasinya
/// di lapisan data (`BackupService`).
abstract interface class BackupGateway {
  /// Ringkasan isi cadangan sekarang ("142 transaksi, 4 dompet, sejak 3 Jun"),
  /// tanpa membuat berkasnya.
  Future<Either<Failure, BackupSummary>> summary();

  /// Membuat berkas cadangan. Berkas diperiksa lagi sebelum diserahkan: cadangan
  /// yang tidak bisa dipulihkan tidak pernah sampai ke pengguna. [cancel] yang
  /// diaktifkan → kode `cancelled`.
  Future<Either<Failure, BackupFile>> create({ExportCancel? cancel});

  /// Kapan terakhir cadangan tersimpan di perangkat ini, `null` bila belum
  /// pernah ("Belum pernah dicadangkan").
  Future<Either<Failure, DateTime?>> lastBackupAt();

  /// Mencatat bahwa cadangan baru saja tersimpan. Dipanggil hanya bila
  /// penyimpanan terkonfirmasi (EXPORT_BACKUP §6.1, ADR-040 §3.5).
  Future<Either<Failure, Unit>> recordBackup();
}
