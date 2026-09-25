/// Jenis sebuah `DeductionRule`.
enum DeductionKind {
  /// Nilai per mil dari gaji kotor. Lihat `DeductionRule.value`.
  percentage,

  /// Nominal tetap dalam sen, tidak bergantung pada gaji kotor.
  fixedAmount,
}
