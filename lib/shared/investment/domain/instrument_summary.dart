import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/investment/domain/instrument.dart';
import 'package:saldough/shared/investment/domain/instrument_position.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Nilai yang lebih tua dari ini ditandai (keputusan 10, ADR-049 §3.4).
const staleAfterDays = 30;

/// Valuasi terakhir [instrumentId] pada atau sebelum [asOf] dari
/// [valuations], atau `null`.
InstrumentValuation? latestValuation(String instrumentId, Iterable<InstrumentValuation> valuations, {DateTime? asOf}) {
  InstrumentValuation? best;
  for (final v in valuations) {
    if (v.instrumentId != instrumentId) continue;
    if (asOf != null && v.date.isAfter(DateTime(asOf.year, asOf.month, asOf.day))) continue;
    if (best == null || v.date.isAfter(best.date)) best = v;
  }
  return best;
}

/// Ringkasan satu instrumen untuk layar dan Total aset (WEALTH_ASSETS §5.3):
/// posisi, valuasi terakhir, nilai pasar, untung/rugi belum terwujud, dan
/// kesegaran.
final class InstrumentSummary extends Equatable {
  /// Membuat [InstrumentSummary].
  const InstrumentSummary({required this.instrument, required this.position, this.valuation});

  /// Ringkasan [instrument] dari transaksi dan valuasinya, pada [asOf]
  /// (bawaan: semua).
  factory InstrumentSummary.of(
    Instrument instrument,
    Iterable<Transaction> transactions,
    Iterable<InstrumentValuation> valuations, {
    DateTime? asOf,
  }) => InstrumentSummary(
    instrument: instrument,
    position: InstrumentPosition.replay(instrument, transactions, asOf: asOf),
    valuation: latestValuation(instrument.id, valuations, asOf: asOf),
  );

  /// Instrumennya.
  final Instrument instrument;

  /// Posisi hasil pemutaran ulang.
  final InstrumentPosition position;

  /// Valuasi terakhir, atau `null` bila belum pernah divaluasi.
  final InstrumentValuation? valuation;

  /// Belum pernah divaluasi: nilai pasar memakai nilai perolehan.
  bool get neverValued => valuation == null;

  /// Nilai pasar dalam sen: jumlah × harga terakhir, atau nilai perolehan
  /// bila belum pernah divaluasi.
  int get marketValue => switch (valuation) {
    final v? => marketValueOf(instrument.type, position.quantity, v.unitPrice),
    null => position.cost,
  };

  /// Untung/rugi belum terwujud: nilai pasar − nilai perolehan.
  int get unrealized => marketValue - position.cost;

  /// Hari sejak valuasi terakhir pada [today], atau `null` bila belum pernah.
  int? ageInDays(DateTime today) {
    final v = valuation;
    if (v == null) return null;
    return DateTime(today.year, today.month, today.day).difference(v.date).inDays;
  }

  /// Valuasi terakhir ≥ [staleAfterDays] hari pada [today].
  bool isStale(DateTime today) => (ageInDays(today) ?? 0) >= staleAfterDays;

  @override
  List<Object?> get props => [instrument, position, valuation];
}

/// Σ nilai pasar instrumen Aktif (lapis Investasi, ADR-049 §3.10).
int investmentLayerValue(Iterable<InstrumentSummary> summaries) =>
    summaries.where((s) => s.position.isActive).fold<int>(0, (sum, s) => sum + s.marketValue);

/// Banyak instrumen Aktif, untuk batas Gratis (ADR-049 §3.12).
int activeInstrumentCount(Iterable<InstrumentSummary> summaries) =>
    summaries.where((s) => s.position.isActive).length;
