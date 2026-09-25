// Cabang generik di bawah sengaja menangkap Object (termasuk StateError dan
// Error lain), bukan cuma Exception — itu poin utama guard(): jadi jaring
// pengaman terakhir untuk exception apa pun yang belum dipetakan cabang lain,
// lalu diteruskan ke mapCustomError(). Lihat ADR-0005 bagian 4.
// ignore_for_file: avoid_catches_without_on_clauses

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';

/// Memusatkan pemetaan exception mentah menjadi [Failure], supaya setiap
/// implementasi repository tidak menulis `try`/`catch` berulang.
///
/// Versi Saldough — tanpa `FlowError`/`DioException` karena MVP tidak punya
/// jaringan — hanya menangani kegagalan Hive dan penguraian JSON. Lihat
/// ADR-0005 bagian 4 untuk versi verbatim yang dikutip dari
/// `flutter-architecture-studi-bank`.
mixin RepositoryGuard {
  /// Menjalankan [run], membungkus hasilnya jadi `Right`, atau memetakan
  /// exception yang terlempar jadi `Left<Failure>`.
  Future<Either<Failure, T>> guard<T>(Future<T> Function() run) async {
    try {
      return right(await run());
    } on FormatException catch (e, st) {
      return left(SystemFailure(
        code: const FailureCode('PERSISTENCE_PARSE_ERROR'),
        message: e.message,
        details: FailureDetails(cause: e, stackTrace: st),
      ));
    } on Failure catch (e) {
      // Paket penyimpanan (hive_storage, api_storage) sudah melempar
      // Failure yang tepat (PersistenceFailure dkk) — teruskan apa adanya.
      return left(e);
    } catch (e) {
      final custom = mapCustomError(e);
      if (custom != null) return left(custom);
      return left(SystemFailure(code: FailureCode.unknown, message: e.toString()));
    }
  }

  /// Varian [guard] untuk operasi tanpa nilai balik.
  Future<Either<Failure, Unit>> guardVoid(Future<void> Function() run) =>
      guard(() async {
        await run();
        return unit;
      });

  /// Hook untuk memetakan exception spesifik fitur. Override di implementasi
  /// repository yang butuh pemetaan tambahan (lihat
  /// `CycleRepositoryImpl.mapCustomError` di ARCHITECTURE_OVERVIEW.md).
  Failure? mapCustomError(Object error) => null;
}
