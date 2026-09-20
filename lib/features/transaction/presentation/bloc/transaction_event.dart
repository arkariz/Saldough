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

/// Memuat ulang dompet dan transaksi bulan yang sedang tampil TANPA
/// `isLoading` -- dikirim sesudah alur CATAT selesai (transaksi baru dan
/// saldo dompet yang berubah harus muncul di daftar), ketika daftar sudah
/// tampil dan tidak boleh berkedip jadi kerangka pemuatan.
final class TransactionRefreshed extends TransactionEvent {
  /// Membuat [TransactionRefreshed].
  const TransactionRefreshed();
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

/// Mengganti kata kunci pencarian teks. String kosong berarti "tanpa
/// pencarian".
final class TransactionSearchChanged extends TransactionEvent {
  /// Membuat [TransactionSearchChanged].
  const TransactionSearchChanged(this.query);

  /// Kata kunci baru, dicocokkan ke kategori, catatan, dan nama dompet.
  final String query;
}

/// Menyimpan hasil penyuntingan satu transaksi (FR-TXN-005). [updated]
/// membawa `id` yang SAMA dengan [original] -- penyuntingan menimpa
/// transaksinya, tidak pernah mencatat transaksi penyeimbang. [original]
/// dibawa serta karena `RecordTransaction` butuh tanggal dan dompet lamanya:
/// pindah bulan menghapus dokumen asal lebih dulu (T-1.4), dan dompet lama
/// maupun baru sama-sama dihitung ulang saldonya (T-1.6).
final class TransactionUpdated extends TransactionEvent {
  /// Membuat [TransactionUpdated].
  const TransactionUpdated({required this.original, required this.updated});

  /// Transaksi sebelum disunting.
  final Transaction original;

  /// Transaksi setelah disunting, `id` sama dengan [original].
  final Transaction updated;
}

/// Menghapus satu transaksi dari riwayat (FR-TXN-005). Saldo dompet yang
/// tersentuh dihitung ulang tanpa transaksi ini.
final class TransactionDeleted extends TransactionEvent {
  /// Membuat [TransactionDeleted].
  const TransactionDeleted(this.transaction);

  /// Transaksi yang dihapus.
  final Transaction transaction;
}
