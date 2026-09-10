import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/income/domain/income_source.dart';

/// Kontrak akses data [IncomeSource]. Lihat ADR-0005 — selalu
/// `Either<Failure, T>`, tidak pernah `throw Failure`.
abstract interface class IncomeSourceRepository {
  /// Daftar seluruh sumber pemasukan terdaftar.
  Future<Either<Failure, List<IncomeSource>>> listSources();

  /// Membaca satu sumber ber-`id` [id], atau `Right(null)` kalau tidak ada.
  Future<Either<Failure, IncomeSource?>> getSource(String id);

  /// Menyimpan [source] — menambah kalau `id` baru, menimpa kalau sudah ada.
  Future<Either<Failure, Unit>> saveSource(IncomeSource source);

  /// Menghapus sumber ber-`id` [id]. Tidak berefek kalau `id` tidak ditemukan.
  Future<Either<Failure, Unit>> deleteSource(String id);
}
