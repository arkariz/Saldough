import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_status.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Menghitung angka turunan sebuah [Budget] — `spent`, `remaining`,
/// `progress`, status tiap pos, dan status anggaran. Dart murni, tanpa I/O.
/// Tidak satu pun hasilnya disimpan; dihitung ulang setiap kali diakses.
/// Lihat DOMAIN_MODEL.md bagian "Pos anggaran" untuk rumusnya.
///
/// ⚠ `spent` sebuah pos menjumlahkan **dua** jenis transaksi yang
/// `budgetItemId`-nya menunjuk pos itu:
/// - [ExpenseTransaction] yang `walletId`-nya sama dengan `budget.walletId`;
/// - [TransferTransaction] yang `fromWalletId`-nya sama dengan
///   `budget.walletId`.
///
/// Melewatkan salah satunya membuat angka anggaran salah tanpa gejala.
/// Pemasukan tidak pernah terhitung, dan tidak ada saringan tanggal —
/// tautan pos yang menentukan, bukan periode.
final class CalculateBudgetProgress {
  /// Membuat [CalculateBudgetProgress].
  const CalculateBudgetProgress();

  /// Menghitung progres [budget] dari [transactions] pada saat [now].
  ///
  /// [transactions] boleh berisi transaksi apa saja — yang tidak tertaut ke
  /// pos [budget] diabaikan.
  BudgetProgress call(Budget budget, Iterable<Transaction> transactions, {required DateTime now}) {
    final spentByItem = <String, int>{for (final item in budget.items) item.id: 0};
    for (final transaction in transactions) {
      final (itemId, walletId) = switch (transaction) {
        ExpenseTransaction(:final budgetItemId, :final walletId) => (budgetItemId, walletId),
        TransferTransaction(:final budgetItemId, :final fromWalletId) => (budgetItemId, fromWalletId),
        IncomeTransaction() => (null, null),
      };
      if (itemId == null || walletId != budget.walletId) continue;
      final current = spentByItem[itemId];
      if (current == null) continue;
      spentByItem[itemId] = current + transaction.amount;
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

/// `spent ÷ plannedAmount`, tidak dijepit — lewat anggaran menghasilkan nilai
/// di atas 1. Rencana nol tidak bisa dibagi: hasilnya 0 kalau belum ada yang
/// terpakai, dan 1 kalau sudah (statusnya tetap `overspent`, yang membawa
/// makna "lewat anggaran").
double progressRatio({required int spent, required int plannedAmount}) {
  if (plannedAmount <= 0) return spent > 0 ? 1 : 0;
  return spent / plannedAmount;
}
