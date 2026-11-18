import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/investment/domain/instrument.dart';

/// Penyimpanan instrumen dan valuasinya (ADR-049 §3.9). Aturan bisnis ada di
/// use case, bukan di sini.
abstract interface class InvestmentRepository {
  /// Semua instrumen, urut dibuat.
  Future<Either<Failure, List<Instrument>>> listInstruments();

  /// Menyimpan [instrument] baru atau menimpa yang ber-`id` sama.
  Future<Either<Failure, Unit>> saveInstrument(Instrument instrument);

  /// Menghapus instrumen [id] beserta seluruh valuasinya.
  Future<Either<Failure, Unit>> deleteInstrument(String id);

  /// Semua valuasi, urut instrumen lalu tanggal.
  Future<Either<Failure, List<InstrumentValuation>>> listValuations();

  /// Menyimpan [valuations] dalam satu tulis; valuasi instrumen dan tanggal
  /// yang sama diganti.
  Future<Either<Failure, Unit>> saveValuations(List<InstrumentValuation> valuations);

  /// Menghapus valuasi [instrumentId] pada [date].
  Future<Either<Failure, Unit>> deleteValuation(String instrumentId, DateTime date);
}
