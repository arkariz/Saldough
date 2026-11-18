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
    required this.investBuy,
    required this.investSell,
    this.goalsSheet = 'Goals',
    this.goalColumns = const ['Name', 'Target', 'Saved', 'Status', 'Target date', 'Wallets'],
    this.goalStatuses = const ['Active', 'Reached', 'Archived'],
    this.investmentsSheet = 'Investments',
    this.investmentColumns = const [
      'Name',
      'Type',
      'Ticker',
      'Quantity',
      'Unit',
      'Cost',
      'Last price',
      'Price unit',
      'Price date',
      'Market value',
      'Unrealized gain/loss',
      'Realized gain/loss',
      'Status',
    ],
    this.investmentTypes = const ['Stock', 'Mutual fund', 'Bond', 'Gold', 'Other'],
    this.quantityUnits = const ['lot', 'units', 'face value', 'g', 'units'],
    this.priceUnits = const ['per share', 'per unit', '% of face value', 'per gram', 'per unit'],
    this.investmentStatuses = const ['Active', 'Closed'],
    this.valuationsSheet = 'Values',
    this.valuationColumns = const ['Date', 'Investment', 'Price', 'Price unit', 'Source'],
    this.valuationSources = const ['Manual', 'Google Sheet'],
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

  /// Teks jenis pembelian investasi (ADR-049 §3.9).
  final String investBuy;

  /// Teks jenis penjualan investasi (ADR-049 §3.9).
  final String investSell;

  /// Nama lembar tujuan tabungan (ADR-048 §3.4).
  final String goalsSheet;

  /// Judul 6 kolom tujuan: Nama, Target, Terkumpul, Status, Target tanggal,
  /// Dompet.
  final List<String> goalColumns;

  /// Teks status tujuan, urut `SavingsGoalStatus.values`.
  final List<String> goalStatuses;

  /// Nama lembar investasi (ADR-049 §3.9).
  final String investmentsSheet;

  /// Judul 13 kolom investasi.
  final List<String> investmentColumns;

  /// Teks jenis, urut `InstrumentType.values`.
  final List<String> investmentTypes;

  /// Satuan jumlah, urut `InstrumentType.values`.
  final List<String> quantityUnits;

  /// Satuan harga, urut `InstrumentType.values`.
  final List<String> priceUnits;

  /// Teks Aktif dan Selesai.
  final List<String> investmentStatuses;

  /// Nama lembar riwayat nilai.
  final String valuationsSheet;

  /// Judul 5 kolom valuasi.
  final List<String> valuationColumns;

  /// Teks sumber valuasi, urut `ValuationSource.values`.
  final List<String> valuationSources;
}
