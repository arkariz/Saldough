import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';

/// Penyimpanan [AppUpdateMemory] (ADR-039 §3.5). Pemanggil memperlakukan
/// `Left` dari [load] sebagai [AppUpdateMemory.empty]: lebih baik melewatkan
/// lembar daripada menampilkannya berulang.
abstract interface class AppUpdateMemoryRepository {
  /// Membaca ingatan; belum ada berarti [AppUpdateMemory.empty].
  Future<Either<Failure, AppUpdateMemory>> load();

  /// Menyimpan [memory].
  Future<Either<Failure, Unit>> save(AppUpdateMemory memory);
}
