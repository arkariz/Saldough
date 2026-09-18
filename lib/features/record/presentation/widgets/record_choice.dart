/// Tiga pilihan yang ditawarkan CATAT saat dibuka (FR-REC-001).
enum RecordChoice {
  /// Catat pemasukan.
  income,

  /// Catat pengeluaran.
  expense,

  /// Catat transfer antar dompet.
  transfer,
}

/// Nilai sentinel dikembalikan formulir CATAT saat pemakai menekan tombol
/// kembali, membedakannya dari `Navigator.pop(null)` (dibatalkan seluruhnya)
/// dan dari `RecordEvent` (disimpan). `AppShellPage` menafsirkan ini dengan
/// membuka ulang [RecordChoiceSheet], bukan menutup alur CATAT.
final class BackToChoice {
  /// Membuat [BackToChoice].
  const BackToChoice();
}
