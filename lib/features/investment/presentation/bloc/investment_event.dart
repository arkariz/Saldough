part of 'investment_bloc.dart';

/// Peristiwa [InvestmentBloc].
sealed class InvestmentEvent {
  const InvestmentEvent();
}

/// Muat (ulang) instrumen, valuasi, catatan, dan dompet.
final class InvestmentStarted extends InvestmentEvent {
  /// Membuat [InvestmentStarted].
  const InvestmentStarted();
}

/// Simpan instrumen baru atau ubahan. [activeLimit] `null` = Plus.
final class InstrumentSaved extends InvestmentEvent {
  /// Membuat [InstrumentSaved].
  const InstrumentSaved(this.instrument, {this.activeLimit});

  /// Instrumen yang disimpan.
  final Instrument instrument;

  /// Batas instrumen Aktif Gratis.
  final int? activeLimit;
}

/// Hapus instrumen tanpa catatan.
final class InstrumentDeleted extends InvestmentEvent {
  /// Membuat [InstrumentDeleted].
  const InstrumentDeleted(this.instrumentId);

  /// Instrumen yang dihapus.
  final String instrumentId;
}

/// Simpan satu atau banyak valuasi (Perbarui nilai, atau Urungkan hapus).
final class ValuationsSaved extends InvestmentEvent {
  /// Membuat [ValuationsSaved].
  const ValuationsSaved(this.valuations, {this.single = false, this.restore = false});

  /// Valuasi baru.
  final List<InstrumentValuation> valuations;

  /// Dibuka dari Rincian (satu instrumen).
  final bool single;

  /// Urungkan hapus: tanpa analitik dan tanpa pesan.
  final bool restore;
}

/// Hapus satu valuasi dari Riwayat nilai.
final class ValuationDeleted extends InvestmentEvent {
  /// Membuat [ValuationDeleted].
  const ValuationDeleted(this.valuation);

  /// Valuasi yang dihapus.
  final InstrumentValuation valuation;
}
