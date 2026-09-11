import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/investment/domain/entities/allocation_percentage.dart';
import 'package:saldough/features/investment/domain/entities/cycle_investment_snapshot.dart';

/// Port kecil untuk membaca/menulis rencana investasi sebuah siklus —
/// TANPA `investment` mengimpor domain/data milik fitur `cycle` secara
/// langsung (ADR-0009: fitur privat, tidak saling diimpor).
/// Diimplementasikan oleh `features/cycle/data/` dan dikawat di
/// `RootModule`, yang memang melihat kedua fitur — pola yang sama seperti
/// `CycleIncomeWriter` milik fitur `worklog`, hanya di sini juga ada arah
/// baca selain tulis. Lihat catatan revisi ADR-0009.
abstract interface class CycleInvestmentGateway {
  /// Membaca potret rencana investasi siklus ber-`id` [cycleId].
  ///
  /// `Right(null)` kalau siklus belum pernah dibuat.
  Future<Either<Failure, CycleInvestmentSnapshot?>> getSnapshot(String cycleId);

  /// Menulis rencana investasi siklus ber-`id` [cycleId]: [returnDeposit] dan
  /// [allocations] menimpa apa adanya.
  ///
  /// `Left(BusinessRuleFailure)` kalau siklus [cycleId] belum ada, atau
  /// sudah ditutup (ADR-0008 — siklus tertutup tidak menerima penyuntingan
  /// tanpa dibuka kembali secara sadar).
  Future<Either<Failure, Unit>> saveAllocationPlan({
    required String cycleId,
    required int returnDeposit,
    required List<AllocationPercentage> allocations,
  });

  /// Potret seluruh siklus yang SUDAH DITUTUP — dasar perhitungan saldo pos
  /// (T-5.7): hanya alokasi dari siklus tertutup yang ikut terhitung (lihat
  /// DOMAIN_MODEL.md bagian "Pos tujuan dan pinjaman").
  Future<Either<Failure, List<CycleInvestmentSnapshot>>> listClosedCycleSnapshots();

  /// Seluruh `id` siklus yang sudah dibuat, terurut menaik (UX-09: dipakai
  /// untuk pemilih siklus tujuan, bukan mengetik `YYYY-MM` dengan tangan).
  Future<Either<Failure, List<String>>> listCycleIds();
}
