import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_memory.dart';

/// Penyimpanan [PeriodBookMemory] (ADR-045 §3.5).
abstract interface class PeriodBookMemoryStore {
  /// Membaca ingatan; kosong bila belum pernah ditulis.
  Future<Either<Failure, PeriodBookMemory>> load();

  /// Menulis ganti seluruh ingatan.
  Future<Either<Failure, Unit>> save(PeriodBookMemory memory);
}
