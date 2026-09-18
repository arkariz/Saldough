part of 'transaction_bloc.dart';

/// Event [TransactionBloc].
sealed class TransactionEvent {
  /// Membuat [TransactionEvent].
  const TransactionEvent();
}

/// Memuat dompet dan transaksi bulan berjalan -- dikirim sekali saat layar
/// dibuka (dan lagi lewat tombol "Coba lagi" kalau pembacaan gagal).
final class TransactionStarted extends TransactionEvent {
  /// Membuat [TransactionStarted].
  const TransactionStarted();
}

/// Berpindah ke bulan [month] (navigasi bulan sebelumnya/berikutnya) --
/// HANYA memuat ulang transaksi, dompet tidak diambil ulang.
final class TransactionMonthChanged extends TransactionEvent {
  /// Membuat [TransactionMonthChanged].
  const TransactionMonthChanged(this.month);

  /// Bulan tujuan. Hanya tahun dan bulannya dipakai.
  final DateTime month;
}

/// Mengganti filter jenis transaksi.
final class TransactionTypeFilterChanged extends TransactionEvent {
  /// Membuat [TransactionTypeFilterChanged].
  const TransactionTypeFilterChanged(this.filter);

  /// Filter jenis yang baru dipilih.
  final TransactionTypeFilter filter;
}

/// Mengganti filter dompet. `null` berarti "semua dompet".
final class TransactionWalletFilterChanged extends TransactionEvent {
  /// Membuat [TransactionWalletFilterChanged].
  const TransactionWalletFilterChanged(this.walletId);

  /// `id` dompet yang dipilih, atau `null` untuk semua dompet.
  final String? walletId;
}

/// Mengganti filter kategori. `null` berarti "semua kategori".
final class TransactionCategoryFilterChanged extends TransactionEvent {
  /// Membuat [TransactionCategoryFilterChanged].
  const TransactionCategoryFilterChanged(this.categoryKey);

  /// Kunci kategori yang dipilih, atau `null` untuk semua kategori.
  final String? categoryKey;
}
