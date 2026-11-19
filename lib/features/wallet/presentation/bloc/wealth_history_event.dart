part of 'wealth_history_bloc.dart';

/// Event [WealthHistoryBloc].
sealed class WealthHistoryEvent {
  /// Membuat [WealthHistoryEvent].
  const WealthHistoryEvent();
}

/// Memuat riwayat.
final class WealthHistoryStarted extends WealthHistoryEvent {
  /// Membuat [WealthHistoryStarted].
  const WealthHistoryStarted();
}

/// Memilih titik ke-[index] di grafik.
final class WealthHistoryPointSelected extends WealthHistoryEvent {
  /// Membuat [WealthHistoryPointSelected].
  const WealthHistoryPointSelected(this.index);

  /// Indeks titik.
  final int index;
}
