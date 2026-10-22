import 'dart:typed_data';

import 'package:saldough/features/data_portability/domain/backup_summary.dart';

/// Berkas cadangan yang siap disimpan atau dibagikan.
final class BackupFile {
  /// Membuat [BackupFile].
  const BackupFile({required this.name, required this.bytes, required this.summary, required this.createdAt});

  /// Nama berkas, mis. `tanukonomy-cadangan-2026-10-22.tkbak`.
  final String name;

  /// Isi berkas (amplop berversi, gzip).
  final Uint8List bytes;

  /// Ringkasan isinya.
  final BackupSummary summary;

  /// Saat dibuat.
  final DateTime createdAt;
}
