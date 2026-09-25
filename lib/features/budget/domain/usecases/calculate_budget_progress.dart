import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_kind.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_status.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Menghitung angka turunan sebuah [Budget] — `spent`, `remaining`,
/// `progress`, status tiap pos, dan status anggaran. Dart murni, tanpa I/O.
/// Tidak satu pun hasilnya disimpan; dihitung ulang setiap kali diakses.
/// Lihat DOMAIN_MODEL.md bagian "Pos anggaran" untuk rumusnya.
///
/// ⚠ `spent` sebuah pos menjumlahkan transaksi yang `budgetItemId`-nya
/// menunjuk pos itu DAN sejenis dengan posnya (ADR-018) — lihat
/// [countsTowardBudgetItem]. Pemasukan tidak pernah terhitung, dan tidak ada
/// saringan tanggal — tautan pos yang menentukan, bukan periode.
final class CalculateBudgetProgress {
  /// Membuat [CalculateBudgetProgress].
  const CalculateBudgetProgress();

  /// Menghitung progres [budget] dari [transactions] pada saat [now].
  ///
  /// [transactions] boleh berisi transaksi apa saja — yang tidak tertaut ke
  /// pos [budget] diabaikan.
  BudgetProgress call(Budget budget, Iterable<Transaction> transactions, {required DateTime now}) {
    final itemsById = {for (final item in budget.items) item.id: item};
    final spentByItem = <String, int>{for (final item in budget.items) item.id: 0};
    for (final transaction in transactions) {
      final itemId = switch (transaction) {
        ExpenseTransaction(:final budgetItemId) || TransferTransaction(:final budgetItemId) => budgetItemId,
        IncomeTransaction() => null,
      };
      final item = itemsById[itemId];
      if (item == null || !countsTowardBudgetItem(budget, item, transaction)) continue;
      spentByItem[item.id] = spentByItem[item.id]! + transaction.amount;
    }

    final items = [
      for (final item in budget.items) BudgetItemProgress.of(item, spent: spentByItem[item.id]!),
    ];
    final spent = items.fold(0, (sum, item) => sum + item.spent);
    return BudgetProgress(
      plannedAmount: budget.plannedAmount,
      spent: spent,
      status: budget.statusAt(now),
      spendingStatus: BudgetItemStatus.from(spent: spent, plannedAmount: budget.plannedAmount),
      items: items,
    );
  }
}

/// Hasil [CalculateBudgetProgress] untuk satu anggaran.
final class BudgetProgress extends Equatable {
  /// Membuat [BudgetProgress].
  const BudgetProgress({
    required this.plannedAmount,
    required this.spent,
    required this.status,
    required this.spendingStatus,
    required this.items,
  });

  /// Nominal rencana tingkat anggaran, diketik pemilik.
  final int plannedAmount;

  /// `Σ item.spent`, dalam sen.
  final int spent;

  /// Status siklus hidup (aktif/selesai/nonaktif).
  final BudgetStatus status;

  /// Status pakai tingkat anggaran, memakai empat kondisi yang sama dengan
  /// pos, dihitung dari [spent] terhadap [plannedAmount].
  final BudgetItemStatus spendingStatus;

  /// Progres tiap pos, urut sama dengan `budget.items`.
  final List<BudgetItemProgress> items;

  /// `plannedAmount − spent`. Boleh negatif.
  int get remaining => plannedAmount - spent;

  /// `spent ÷ plannedAmount`. Lihat [progressRatio].
  double get progress => progressRatio(spent: spent, plannedAmount: plannedAmount);

  @override
  List<Object?> get props => [plannedAmount, spent, status, spendingStatus, items];
}

/// Progres satu pos anggaran.
final class BudgetItemProgress extends Equatable {
  /// Membuat [BudgetItemProgress].
  const BudgetItemProgress({required this.item, required this.spent, required this.status});

  /// Menurunkan progres [item] dari [spent].
  factory BudgetItemProgress.of(BudgetItem item, {required int spent}) => BudgetItemProgress(
    item: item,
    spent: spent,
    status: BudgetItemStatus.from(spent: spent, plannedAmount: item.plannedAmount),
  );

  /// Pos yang dihitung.
  final BudgetItem item;

  /// Jumlah transaksi tertaut, dalam sen.
  final int spent;

  /// Salah satu dari empat status pos.
  final BudgetItemStatus status;

  /// `plannedAmount − spent`. Boleh negatif.
  int get remaining => item.plannedAmount - spent;

  /// `spent ÷ plannedAmount`. Lihat [progressRatio].
  double get progress => progressRatio(spent: spent, plannedAmount: item.plannedAmount);

  @override
  List<Object?> get props => [item, spent, status];
}

/// Apakah [transaction] terhitung ke [item] milik [budget] (ADR-018),
/// DENGAN anggapan `budgetItemId`-nya sudah menunjuk [item]:
/// - pos pengeluaran: hanya [ExpenseTransaction] yang `walletId`-nya dompet
///   anggaran;
/// - pos transfer: hanya [TransferTransaction] DARI dompet anggaran KE
///   `item.targetWalletId`.
///
/// Satu-satunya tempat aturan ini ditulis — dipakai hitungan progres dan
/// daftar transaksi tertaut, supaya keduanya tidak pernah berbeda.
bool countsTowardBudgetItem(Budget budget, BudgetItem item, Transaction transaction) =>
    switch ((item.kind, transaction)) {
      (BudgetItemKind.expense, ExpenseTransaction(:final walletId)) => walletId == budget.walletId,
      (BudgetItemKind.transfer, TransferTransaction(:final fromWalletId, :final toWalletId)) =>
        fromWalletId == budget.walletId && toWalletId == item.targetWalletId,
      _ => false,
    };

/// `spent ÷ plannedAmount`, tidak dijepit — lewat anggaran menghasilkan nilai
/// di atas 1. Rencana nol tidak bisa dibagi: hasilnya 0 kalau belum ada yang
/// terpakai, dan 1 kalau sudah (statusnya tetap `overspent`, yang membawa
/// makna "lewat anggaran").
double progressRatio({required int spent, required int plannedAmount}) {
  if (plannedAmount <= 0) return spent > 0 ? 1 : 0;
  return spent / plannedAmount;
}
