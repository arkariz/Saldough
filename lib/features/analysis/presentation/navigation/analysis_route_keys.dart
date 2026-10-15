import 'package:navigation/navigation.dart';

// Satu-satunya berkas fitur `analysis` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3).

/// Dari mana Analisis dibuka (analitik, FINANCIAL_ANALYSIS §13A).
enum AnalysisSource {
  /// Tab Riwayat › Analisis.
  history,

  /// Kartu Arus di Beranda.
  home,

  /// Lembar kilas balik di Rencana.
  lookback,
}

/// Input Analisis sebagai rute penuh (dari Beranda dan kilas balik).
final class AnalysisInput extends RouteInput {
  /// Membuat [AnalysisInput].
  const AnalysisInput({required this.source, this.periodStart});

  /// Asal pembukaan.
  final AnalysisSource source;

  /// Tanggal di dalam periode yang dibuka; `null` = periode berjalan.
  final DateTime? periodStart;
}

/// Kunci rute fitur `analysis`.
abstract final class AnalysisRouteKeys {
  /// Analisis satu periode sebagai halaman penuh; keluar = kembali.
  static const open = RouteKey<AnalysisInput>('analysis.open');
}
