import 'dart:isolate';
import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/data_portability/data/export_writers.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/export_data.dart';
import 'package:saldough/features/data_portability/domain/export_gateway.dart';
import 'package:saldough/features/data_portability/domain/export_labels.dart';
import 'package:saldough/features/data_portability/domain/export_models.dart';
import 'package:saldough/features/data_portability/domain/export_rows.dart';

/// Ekspor transaksi ke spreadsheet (FR-DAT-001, EXPORT_BACKUP §5). Tanpa
/// pilihan rentang: selalu seluruh data saat ini.
final class ExportService with RepositoryGuard implements ExportGateway {
  /// Membuat [ExportService]. [labels] dipanggil saat ekspor supaya mengikuti
  /// bahasa aplikasi saat itu.
  ExportService({required this._source, required this._labels, this._now = DateTime.now});

  final ExportDataSource _source;
  final ExportLabels Function() _labels;
  final DateTime Function() _now;

  @override
  Failure? mapCustomError(Object error) =>
      error is BackupException ? BusinessRuleFailure(code: error.code, message: error.message) : null;

  @override
  Future<Either<Failure, ExportPreview>> preview() => guard(() async {
    final data = await _load();
    if (data.transactions.isEmpty) return const ExportPreview(count: 0, firstDate: null, lastDate: null);
    final dates = [for (final t in data.transactions) t.date]..sort();
    return ExportPreview(count: dates.length, firstDate: dates.first, lastDate: dates.last);
  });

  @override
  Future<Either<Failure, ExportFile>> export(ExportFormat format, {ExportCancel? cancel}) => guard(() async {
    final data = await _load();
    if (data.transactions.isEmpty) {
      throw const BackupException(BackupFailureCodes.emptyExport, 'tidak ada transaksi');
    }
    _throwIfCancelled(cancel);

    final labels = _labels();
    final rowCount = data.transactions.length;
    final bytes = await _buildInIsolate(data, format, labels);
    _throwIfCancelled(cancel);

    final now = _now();
    final day =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return ExportFile(
      name: 'tanukonomy-${labels.fileStem}-$day.${format.extension}',
      bytes: bytes,
      format: format,
      rowCount: rowCount,
    );
  });

  // `Failure` bukan Exception; `RepositoryGuard.guard` meneruskannya apa adanya.
  // ignore: only_throw_errors
  Future<ExportData> _load() async => (await _source.load()).getOrElse((failure) => throw failure);

  static void _throwIfCancelled(ExportCancel? cancel) {
    if (cancel != null && cancel.isCancelled) {
      throw const BackupException(BackupFailureCodes.cancelled, 'dibatalkan pengguna');
    }
  }
}

/// Membangun berkas di isolate. Dipisah ke fungsi tingkat atas dengan argumen
/// eksplisit: closure yang dibuat di dalam metode [ExportService] ikut membawa
/// `this` (dan lewat itu repositori serta kotak Hive yang tidak bisa dikirim
/// antar isolate), sehingga ekspor gagal di perangkat walau lolos di uji.
Future<Uint8List> _buildInIsolate(ExportData data, ExportFormat format, ExportLabels labels) => Isolate.run(() {
  final rows = buildExportRows(data);
  return switch (format) {
    ExportFormat.xlsx => ExportWriters.xlsx(data, rows, labels),
    ExportFormat.csv => ExportWriters.csv(data, rows, labels),
  };
});
