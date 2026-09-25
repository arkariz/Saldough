/// Status pakai sebuah pos anggaran, diturunkan dari `spent` dan
/// `plannedAmount` — tidak pernah disimpan. Lihat DOMAIN_MODEL.md bagian
/// "Pos anggaran".
enum BudgetItemStatus {
  /// Belum terpakai: `spent = 0`.
  planned,

  /// Terpakai sebagian: `0 < spent < plannedAmount`.
  partiallySpent,

  /// Selesai: `spent = plannedAmount`.
  completed,

  /// Lewat anggaran: `spent > plannedAmount`.
  overspent;

  /// Menurunkan status dari [spent] terhadap [plannedAmount], keduanya sen.
  static BudgetItemStatus from({required int spent, required int plannedAmount}) {
    if (spent == 0) return BudgetItemStatus.planned;
    if (spent < plannedAmount) return BudgetItemStatus.partiallySpent;
    if (spent == plannedAmount) return BudgetItemStatus.completed;
    return BudgetItemStatus.overspent;
  }
}
