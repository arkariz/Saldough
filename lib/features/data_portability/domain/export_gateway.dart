import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/data_portability/domain/export_models.dart';

/// Ekspor transaksi ke spreadsheet (FR-DAT-001, EXPORT_BACKUP §5). Tanpa
/// pilihan rentang: selalu seluruh data saat ini. Implementasinya di lapisan
/// data (`ExportService`).
abstract interface class ExportGateway {
  /// Ringkasan sebelum ekspor, tanpa membangun berkasnya.
  Future<Either<Failure, ExportPreview>> preview();

  /// Membangun berkas ekspor dalam [format]. Belum ada transaksi → kode
  /// `emptyExport`; dibatalkan lewat [cancel] → `cancelled`.
  Future<Either<Failure, ExportFile>> export(ExportFormat format, {ExportCancel? cancel});
}
