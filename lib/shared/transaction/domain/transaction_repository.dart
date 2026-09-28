import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';

/// Kontrak akses data [Transaction]. Lihat ADR-0005 — selalu
/// `Either<Failure, T>`, tidak pernah `throw Failure`.
///
/// Buku besar dipartisi per bulan (lihat
/// [ADR-012](../../../docs/02-architecture/adr/0012-tata-letak-penyimpanan-buku-besar.md)),
/// jadi kontrak ini sengaja tidak punya `listTransactions()` polos — pemanggil
/// selalu menyatakan lingkupnya: satu bulan untuk merender layar, atau
/// seluruh riwayat untuk menghitung ulang saldo.
abstract interface class TransactionRepository {
  /// Seluruh transaksi yang tanggalnya jatuh pada bulan [month] — hanya
  /// tahun dan bulannya yang dipakai, tanggal dan waktunya diabaikan.
  Future<Either<Failure, List<Transaction>>> listTransactionsInMonth(DateTime month);

  /// Seluruh transaksi di seluruh riwayat, lintas bulan.
  ///
  /// ⚠ Memuat setiap dokumen bulan yang pernah ditulis. Dipakai untuk
  /// `CalculateWalletBalance` dan `recomputeWalletBalances()` (T-1.5/T-1.6),
  /// **bukan** untuk merender layar — layar memakai [listTransactionsInMonth].
  Future<Either<Failure, List<Transaction>>> listAllTransactions();

  /// Paling banyak [limit] transaksi terbaru, tanggal terbaru di atas.
  ///
  /// Membaca dokumen bulan dari yang terbaru ke belakang dan berhenti begitu
  /// [limit] terpenuhi, jadi biayanya mengikuti [limit], bukan panjang
  /// riwayat (NFR-PERF-002). Dipakai Beranda (FR-HOME-004).
  Future<Either<Failure, List<Transaction>>> listRecentTransactions(int limit);

  /// Bulan (tanggal selalu hari pertama) yang pernah punya transaksi,
  /// terurut naik -- dibaca dari dokumen indeks saja, tanpa membuka satu pun
  /// dokumen bulan.
  ///
  /// Dipakai untuk pencarian lintas bulan (T-8.2): pemanggil tahu bulan mana
  /// saja yang ADA sebelum memutuskan bulan mana yang dibuka lewat
  /// [listTransactionsInMonth], jadi jalur layar tidak pernah perlu
  /// [listAllTransactions].
  Future<Either<Failure, List<DateTime>>> listAvailableMonths();

  /// Menyimpan [transaction] — menambah kalau `id` baru, menimpa kalau
  /// sudah ada.
  ///
  /// Beri [previousDate] saat menyunting transaksi yang sudah ada, diisi
  /// tanggalnya **sebelum** disunting. Kalau bulan [previousDate] berbeda
  /// dari bulan `transaction.date`, transaksi dipindah: dihapus dari
  /// dokumen bulan lama lebih dulu, baru ditambahkan ke dokumen bulan baru
  /// — supaya kegagalan di tengah tidak menghasilkan transaksi ganda.
  /// Biarkan `null` untuk transaksi baru.
  Future<Either<Failure, Unit>> saveTransaction(Transaction transaction, {DateTime? previousDate});

  /// Menghapus transaksi ber-`id` [id] yang tercatat pada bulan [date].
  /// Tidak berefek kalau `id` tidak ditemukan pada bulan itu.
  Future<Either<Failure, Unit>> deleteTransaction(String id, DateTime date);
}
