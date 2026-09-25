/// Jenis pos anggaran (ADR-018): menentukan transaksi jenis apa yang boleh
/// ditautkan dan terhitung ke pos itu.
enum BudgetItemKind {
  /// Rencana belanja. Hanya pengeluaran dari dompet anggaran yang terhitung.
  /// Nominal boleh dirinci jadi jumlah × harga satuan.
  expense,

  /// Rencana pemindahan dana, misalnya setoran tabungan. Hanya transfer DARI
  /// dompet anggaran KE `BudgetItem.targetWalletId` yang terhitung. Nominal
  /// selalu diketik langsung.
  transfer,
}
