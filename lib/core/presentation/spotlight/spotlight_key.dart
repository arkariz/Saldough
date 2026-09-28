/// Kunci stabil tiap elemen yang bisa disorot tur (ONBOARDING_PLAN §4.3).
/// Dipasang lewat `SpotlightTarget` di titik pemakaian widget-nya.
enum SpotlightKey {
  /// Kartu total saldo Beranda.
  homeBalance,

  /// Slot CATAT navigasi bawah.
  homeRecord,

  /// Arus bulan ini di Beranda.
  homeCashFlow,

  /// Kartu anggaran aktif Beranda.
  homeBudget,

  /// Pengalih jenis CATAT.
  recordKind,

  /// Bidang nominal CATAT.
  recordAmount,

  /// Pemilih dompet CATAT.
  recordWallet,

  /// Pemilih pos anggaran CATAT.
  recordBudgetItem,

  /// Kartu ringkasan tab Dompet.
  walletSummary,

  /// Kartu dompet pertama.
  walletCard,

  /// Tombol tambah dompet.
  walletAdd,

  /// Konsol bulan tab Transaksi.
  txnMonth,

  /// Baris cari dan Filter tab Transaksi.
  txnFilter,

  /// Baris transaksi pertama.
  txnRow,

  /// Kartu ringkasan tab Anggaran.
  budgetSummary,

  /// Penyaring status anggaran.
  budgetFilter,

  /// Tombol Template Anggaran.
  budgetTemplates,

  /// Kartu pos pertama di rincian anggaran.
  budgetDetailItem,

  /// Tombol catat di kartu pos pertama.
  budgetDetailRecord,

  /// Proyek pertama atau tombol tambah proyek di ikhtisar Freelance.
  freelanceProject,

  /// Tab worklog rincian proyek.
  freelanceWorklog,

  /// Aksi "catat diterima" pembayaran tertunda.
  freelanceReceive,
}
