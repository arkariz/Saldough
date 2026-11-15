import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';
import 'package:saldough/features/period_book/domain/entities/ritual_info.dart';

/// Sumber isi buku (port milik `period_book`, ADR-0009, ADR-045 §3.2).
/// Diimplementasi di `lib/app/period_book/` dengan memanggil model baca
/// Analisis, Arus Beranda, dan Rencana; tidak ada aturan hitung di sini.
abstract interface class PeriodBookSource {
  /// Isi buku [period], dihitung langsung dari data (BP-4).
  Future<Either<Failure, PeriodBookContent>> contentFor(ClosedPeriod period);

  /// Bahan ritual Tutup buku untuk [period] (BP-5, BP-6): hanya membaca, tidak
  /// mengubah apa pun.
  Future<Either<Failure, RitualInfo>> ritualFor(ClosedPeriod period);
}
