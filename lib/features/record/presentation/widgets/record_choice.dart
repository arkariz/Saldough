/// Tiga jenis yang ditawarkan CATAT (FR-REC-001), dipilih lewat
/// `RecordKindSwitcher` di atas formulir (UX-1).
enum RecordChoice {
  /// Catat pemasukan.
  income,

  /// Catat pengeluaran.
  expense,

  /// Catat transfer antar dompet.
  transfer,
}

/// Nilai sentinel dikembalikan formulir pemasukan saat pemakai memilih kartu
/// Freelance (FR-FRL-005: CATAT → Catat Pemasukan → Freelance).
/// `openRecordSheet` menafsirkannya dengan menutup alur CATAT lalu membuka
/// Ikhtisar Freelance.
final class OpenFreelance {
  /// Membuat [OpenFreelance].
  const OpenFreelance();
}
