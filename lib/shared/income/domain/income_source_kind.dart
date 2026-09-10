/// Jenis sebuah `IncomeSource`.
enum IncomeSourceKind {
  /// Gaji bulanan tetap, misalnya `Gaji Koko`.
  fixedSalary,

  /// Penghasilan freelance dihitung dari jam kerja, misalnya `Gaji Menul`.
  hourlyFreelance,

  /// Pemasukan sekali jalan, tanpa nominal atau tarif baku.
  adHoc,
}
