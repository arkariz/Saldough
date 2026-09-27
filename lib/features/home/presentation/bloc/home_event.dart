part of 'home_bloc.dart';

/// Event [HomeBloc].
sealed class HomeEvent {
  /// Membuat [HomeEvent].
  const HomeEvent();
}

/// Memuat Beranda untuk pertama kali (atau lewat "Coba lagi").
final class HomeStarted extends HomeEvent {
  /// Membuat [HomeStarted].
  const HomeStarted();
}

/// Memuat ulang TANPA `isLoading` — dikirim saat tab Beranda dibuka dan
/// sesudah alur yang bisa mengubah angkanya (CATAT, Freelance, rincian
/// transaksi) selesai.
final class HomeRefreshed extends HomeEvent {
  /// Membuat [HomeRefreshed].
  const HomeRefreshed();
}
