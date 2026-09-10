/// Jenis sebuah `BudgetLine`.
enum BudgetLineKind {
  /// Nominal diketik pemilik secara langsung.
  manual,

  /// Nominal dihitung dari `rollUpSource`, tidak bisa disunting langsung.
  rollUp,
}
