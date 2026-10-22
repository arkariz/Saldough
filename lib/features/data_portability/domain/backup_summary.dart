/// Ringkasan isi cadangan untuk pratinjau dan daftar cadangan (B-51). Pratinjau
/// pulihkan menghitungnya dari dokumen, bukan dari ringkasan di amplop.
final class BackupSummary {
  /// Membuat [BackupSummary].
  const BackupSummary({
    required this.transactions,
    required this.wallets,
    required this.firstDate,
    required this.currency,
  });

  /// Jumlah transaksi.
  final int transactions;

  /// Jumlah dompet.
  final int wallets;

  /// Tanggal transaksi paling awal (`YYYY-MM-DD`), atau `null` bila kosong.
  final String? firstDate;

  /// Kode mata uang, atau `null` bila belum tersimpan.
  final String? currency;

  /// Bentuk JSON untuk amplop.
  Map<String, Object?> toJson() => {
    'transactions': transactions,
    'wallets': wallets,
    'firstDate': firstDate,
    'currency': currency,
  };
}
