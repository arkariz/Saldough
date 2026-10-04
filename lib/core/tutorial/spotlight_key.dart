/// Kunci stabil tiap elemen yang bisa disorot tur (ONBOARDING_PLAN §4.3),
/// sekaligus satuan progres tutorial (ADR-021 §3.1): yang disimpan adalah
/// langkah yang sudah dilihat, jadi [name] tidak boleh diganti tanpa migrasi.
/// Dipasang lewat `SpotlightTarget` di titik pemakaian widget-nya.
enum SpotlightKey {
  /// Kartu total saldo Beranda.
  homeBalance,

  /// Tombol CATAT (FAB kanan bawah shell).
  homeRecord,

  /// Tombol catat pakai suara (FAB di atas CATAT, ADR-027).
  homeVoice,

  /// Baris perkiraan saldo di Beranda (T-15.13).
  homeForecast,

  /// Kartu Menunggu dicatat di Beranda (T-15.6).
  homePending,

  /// Arus bulan ini di Beranda.
  homeCashFlow,

  /// Kartu anggaran aktif Beranda.
  homeBudget,

  /// Kartu ringkasan Freelance Beranda.
  homeFreelance,

  /// Bagian transaksi terbaru Beranda.
  homeRecent,

  /// Pengalih jenis CATAT.
  recordKind,

  /// Kartu "Honor freelance?" di formulir Pemasukan CATAT.
  recordFreelance,

  /// Bidang nominal CATAT.
  recordAmount,

  /// Pemilih dompet CATAT.
  recordWallet,

  /// Pemilih pos anggaran CATAT.
  recordBudgetItem,

  /// Bidang Ulangi CATAT (T-15.3).
  recordRepeat,

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

  /// Sub-tab Rencana (Anggaran / Rutin), T-15.4.
  planTabs,

  /// Kartu Uang nganggur di segmen Bulan ini (T-15.13).
  planUnplanned,

  /// Kartu Saldo dompet ≈ di segmen Bulan ini (T-15.13).
  planForecast,

  /// Sakelar Ulangi tiap periode di formulir anggaran (ADR-036, T-16.3).
  budgetRepeat,

  /// Pemilih bulan di segmen Bulan ini (ADR-036, T-16.6).
  planMonthPicker,

  /// Chip pembuka di keadaan kosong segmen Rutin.
  recurringStarters,

  /// Kartu "Sisa rutin keluar" segmen Rutin.
  recurringSummary,

  /// Baris menunggu dicatat pertama di segmen Rutin.
  recurringPending,

  /// Tombol tambah rutin.
  recurringAdd,

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
