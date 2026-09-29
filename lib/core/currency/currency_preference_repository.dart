import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/currency/app_currency.dart';

/// Penyimpanan pilihan mata uang (ADR-025 §3.5).
///
/// Pemanggil memperlakukan `Left` dari [load] sebagai [AppCurrency.idr] —
/// pilihan yang rusak berarti bawaan, bukan aplikasi gagal dibuka.
abstract interface class CurrencyPreferenceRepository {
  /// Mata uang tersimpan; belum pernah dipilih atau kode tak dikenal berarti
  /// [AppCurrency.idr].
  Future<Either<Failure, AppCurrency>> load();

  /// Menyimpan [currency] sebagai pilihan.
  Future<Either<Failure, Unit>> save(AppCurrency currency);
}
