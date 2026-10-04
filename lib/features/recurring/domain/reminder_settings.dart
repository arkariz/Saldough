import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';

/// Sakelar global pengingat rutin (ADR-035 §3.8). Bawaannya mati: izin
/// notifikasi baru diminta saat pengguna pertama menyalakannya.
abstract interface class ReminderSettingsRepository {
  /// Apakah pengingat rutin nyala.
  Future<Either<Failure, bool>> isEnabled();

  /// Menyimpan sakelar.
  Future<Either<Failure, Unit>> setEnabled({required bool enabled});
}
