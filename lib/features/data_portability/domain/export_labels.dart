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
    required this.adjustmentIncrease,
    required this.adjustmentDecrease,
    this.goalsSheet = 'Goals',
    this.goalColumns = const ['Name', 'Target', 'Saved', 'Status', 'Target date', 'Wallets'],
    this.goalStatuses = const ['Active', 'Reached', 'Archived'],
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

  /// Teks jenis penyesuaian saldo yang menambah saldo (ADR-047 §3.7).
  final String adjustmentIncrease;

  /// Teks jenis penyesuaian saldo yang mengurangi saldo (ADR-047 §3.7).
  final String adjustmentDecrease;

  /// Nama lembar tujuan tabungan (ADR-048 §3.4).
  final String goalsSheet;

  /// Judul 6 kolom tujuan: Nama, Target, Terkumpul, Status, Target tanggal,
  /// Dompet.
  final List<String> goalColumns;

  /// Teks status tujuan, urut `SavingsGoalStatus.values`.
  final List<String> goalStatuses;
}
