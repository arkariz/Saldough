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

/// Mengganti jenis yang dianalisis: pengeluaran atau pemasukan (F2).
final class AnalysisKindChanged extends AnalysisEvent {
  /// Membuat [AnalysisKindChanged].
  const AnalysisKindChanged(this.kind);

  /// Jenis baru.
  final CategoryKind kind;
}

/// Menyaring ke satu dompet; `null` = semua dompet (F3).
final class AnalysisWalletChanged extends AnalysisEvent {
  /// Membuat [AnalysisWalletChanged].
  const AnalysisWalletChanged(this.walletId);

  /// Dompet yang dipilih, atau `null` = semua.
  final String? walletId;
}

/// Segmen Daftar memindah periode bersama (`HistoryPeriod` berubah): ikut ke
/// periode itu.
final class AnalysisHistorySynced extends AnalysisEvent {
  /// Membuat [AnalysisHistorySynced].
  const AnalysisHistorySynced();
}

/// Memilih kolom tren [index] (F6): hanya memilih, tidak berpindah periode.
final class AnalysisTrendSelected extends AnalysisEvent {
  /// Membuat [AnalysisTrendSelected].
  const AnalysisTrendSelected(this.index);

  /// Indeks kolom di `AnalysisState.trend`.
  final int index;
}

/// Memindah Analisis ke periode yang memuat [date] ("Lihat analisis {periode}").
final class AnalysisPeriodJumped extends AnalysisEvent {
  /// Membuat [AnalysisPeriodJumped].
  const AnalysisPeriodJumped(this.date);

  /// Tanggal di dalam periode tujuan.
  final DateTime date;
}

/// Pindah satu periode ke belakang atau ke depan (F6).
final class AnalysisPeriodStepped extends AnalysisEvent {
  /// Membuat [AnalysisPeriodStepped].
  const AnalysisPeriodStepped({required this.forward});

  /// `true` = ke periode berikutnya.
  final bool forward;
}
