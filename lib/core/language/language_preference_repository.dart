import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';

/// Penyimpanan pilihan bahasa aplikasi (ADR-028 §3.2).
abstract interface class LanguagePreferenceRepository {
  /// Bahasa tersimpan, atau `null` kalau belum pernah dipilih (ikut bahasa
  /// perangkat).
  Future<Either<Failure, AppLocale?>> load();

  /// Menyimpan [locale] sebagai pilihan.
  Future<Either<Failure, Unit>> save(AppLocale locale);
}
