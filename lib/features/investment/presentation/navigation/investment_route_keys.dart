import 'package:navigation/navigation.dart';
import 'package:saldough/shared/investment/investment.dart';

// Satu-satunya berkas fitur `investment` yang boleh diimpor fitur lain
// (ADR-030 §3.3).

/// Masukan rute rincian instrumen.
final class InvestmentDetailInput extends RouteInput {
  /// Membuat [InvestmentDetailInput].
  const InvestmentDetailInput(this.instrumentId);

  /// Instrumen yang dibuka.
  final String instrumentId;
}

/// Masukan rute formulir instrumen: [instrument] `null` = Tambah investasi.
final class InvestmentFormInput extends RouteInput {
  /// Membuat [InvestmentFormInput].
  const InvestmentFormInput({this.instrument});

  /// Instrumen yang diubah, atau `null`.
  final Instrument? instrument;
}

/// Masukan rute Perbarui nilai (rupa B-97 §5): [onlyId] `null` = semua
/// instrumen Aktif.
final class InvestmentValuesInput extends RouteInput {
  /// Membuat [InvestmentValuesInput].
  const InvestmentValuesInput({this.onlyId});

  /// Satu instrumen saja (dari Rincian), atau `null`.
  final String? onlyId;
}

/// Kunci rute fitur investasi (ADR-049 §3.10–§3.11).
abstract final class InvestmentRouteKeys {
  /// Rincian instrumen.
  static const detail = RouteKey<InvestmentDetailInput>('investment.detail');

  /// Formulir Tambah/Ubah investasi.
  static const form = RouteKey<InvestmentFormInput>('investment.form');

  /// Perbarui nilai (massal atau tunggal).
  static const values = RouteKey<InvestmentValuesInput>('investment.values');
}
