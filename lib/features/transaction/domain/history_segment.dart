import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';

/// Bagian tab Riwayat (FINANCIAL_ANALYSIS §6): daftar transaksi atau Analisis.
enum HistorySegment {
  /// Daftar transaksi (bawaan).
  list,

  /// Analisis per kategori.
  analysis,
}

/// Segmen Riwayat yang terakhir dibuka, diingat per perangkat. Preferensi
/// tampilan, bukan data keuangan (B-13).
abstract interface class HistorySegmentRepository {
  /// Segmen tersimpan; bawaan [HistorySegment.list].
  Future<Either<Failure, HistorySegment>> load();

  /// Menyimpan [segment].
  Future<Either<Failure, Unit>> save(HistorySegment segment);
}
