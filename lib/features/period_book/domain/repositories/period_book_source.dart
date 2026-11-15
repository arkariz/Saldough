import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';

/// Sumber isi buku (port milik `period_book`, ADR-0009, ADR-045 §3.2).
/// Diimplementasi di `lib/app/period_book/` dengan memanggil model baca
/// Analisis, Arus Beranda, dan Rencana; tidak ada aturan hitung di sini.
// ignore: one_member_abstracts
abstract interface class PeriodBookSource {
  /// Isi buku [period], dihitung langsung dari data (BP-4).
  Future<Either<Failure, PeriodBookContent>> contentFor(ClosedPeriod period);
}
