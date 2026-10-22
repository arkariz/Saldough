/// Teks berkas ekspor: judul lembar dan kolom mengikuti bahasa aplikasi
/// (EXPORT_BACKUP §5.2). Dibuat pemanggil dari i18n supaya penulis berkas
/// tetap murni dan bisa dijalankan di isolate.
final class ExportLabels {
  /// Membuat [ExportLabels].
  const ExportLabels({
    required this.fileStem,
    required this.transactionsSheet,
    required this.walletsSheet,
    required this.transactionColumns,
    required this.walletColumns,
    required this.income,
    required this.expense,
    required this.transfer,
  });

  /// Kata di nama berkas: `ekspor` atau `export`
  /// (`tanukonomy-ekspor-2026-10-22.xlsx`).
  final String fileStem;

  /// Nama lembar transaksi.
  final String transactionsSheet;

  /// Nama lembar dompet.
  final String walletsSheet;

  /// Judul 14 kolom transaksi, urut: Tanggal, Awal periode, Jenis, Nominal,
  /// Arus, Mata uang, Dompet, Dompet tujuan, Kategori, Catatan, Pos anggaran,
  /// Rutin, Proyek freelance, ID.
  final List<String> transactionColumns;

  /// Judul 3 kolom dompet: Nama, Saldo awal, Saldo sekarang.
  final List<String> walletColumns;

  /// Teks jenis Pemasukan.
  final String income;

  /// Teks jenis Pengeluaran.
  final String expense;

  /// Teks jenis Transfer.
  final String transfer;
}
