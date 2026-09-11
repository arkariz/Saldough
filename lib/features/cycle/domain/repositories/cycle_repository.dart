import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';

/// Kontrak akses data [MonthlyCycle]. Lihat ADR-0005 — selalu
/// `Either<Failure, T>`, tidak pernah `throw Failure`.
abstract interface class CycleRepository {
  /// Membaca siklus ber-`id` [id]. Baris `rollUp`-nya sudah dihitung ulang
  /// dari sumbernya (ADR-0008) — nilai di dokumen tersimpan tidak dipakai.
  ///
  /// `Right(null)` kalau siklus belum pernah dibuat.
  Future<Either<Failure, MonthlyCycle?>> getCycle(String id);

  /// Seluruh `id` siklus yang sudah pernah dibuat, terurut menaik.
  Future<Either<Failure, List<String>>> listCycleIds();

  /// Menyimpan [cycle] — menambah kalau `id` baru, menimpa kalau sudah ada.
  Future<Either<Failure, Unit>> saveCycle(MonthlyCycle cycle);

  /// Menghapus siklus ber-`id` [id]. Tidak ada penjagaan di sini soal siklus
  /// mana yang boleh dihapus (terakhir/belum ditutup) — itu keputusan
  /// presentasi (lihat `CycleBloc`), bukan aturan penyimpanan.
  Future<Either<Failure, Unit>> deleteCycle(String id);
}
