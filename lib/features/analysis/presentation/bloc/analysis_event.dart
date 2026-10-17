part of 'analysis_bloc.dart';

/// Peristiwa [AnalysisBloc].
sealed class AnalysisEvent {
  /// Membuat [AnalysisEvent].
  const AnalysisEvent();
}

/// Layar dibuka; [periodStart] adalah tanggal di dalam periode yang dibuka,
/// atau `null` = periode berjalan.
final class AnalysisStarted extends AnalysisEvent {
  /// Membuat [AnalysisStarted].
  const AnalysisStarted({this.periodStart});

  /// Tanggal di dalam periode yang dibuka, atau `null` = periode berjalan.
  final DateTime? periodStart;
}

/// Muat ulang tanpa kerangka (transaksi, kategori, awal bulan, atau tanggal berubah).
final class AnalysisRefreshed extends AnalysisEvent {
  /// Membuat [AnalysisRefreshed].
  const AnalysisRefreshed();
}

/// Mengetuk irisan donat atau baris legenda (F1): memilih barisnya, mengetuk
/// lagi membatalkan. Lainnya memilih sekaligus membuka anggotanya.
final class AnalysisGroupSelected extends AnalysisEvent {
  /// Membuat [AnalysisGroupSelected].
  const AnalysisGroupSelected(this.key);

  /// [AnalysisGroup.key] baris yang diketuk.
  final String key;
}

/// Pindah satu periode ke belakang atau ke depan (F6).
final class AnalysisPeriodStepped extends AnalysisEvent {
  /// Membuat [AnalysisPeriodStepped].
  const AnalysisPeriodStepped({required this.forward});

  /// `true` = ke periode berikutnya.
  final bool forward;
}
