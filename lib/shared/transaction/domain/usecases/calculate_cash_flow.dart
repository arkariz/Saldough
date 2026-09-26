import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';

/// Pemasukan dan pengeluaran satu bulan, dalam sen (FR-HOME-001).
final class CashFlow extends Equatable {
  /// Membuat [CashFlow].
  const CashFlow({required this.income, required this.expense});

  /// Total pemasukan.
  final int income;

  /// Total pengeluaran.
  final int expense;

  /// Pemasukan dikurangi pengeluaran.
  int get net => income - expense;

  @override
  List<Object?> get props => [income, expense];
}

/// Menjumlahkan pemasukan dan pengeluaran yang tanggalnya jatuh pada bulan
/// kalender [month] — hanya tahun dan bulannya yang dipakai. Dart murni.
///
/// ⚠ Transfer tidak pernah dihitung (aturan 7 CLAUDE.md). Kalau ikut, satu
/// pemindahan Rp1.000.000 tampil sebagai pemasukan sekaligus pengeluaran —
/// dua angka yang sama-sama salah.
final class CalculateCashFlow {
  /// Membuat [CalculateCashFlow].
  const CalculateCashFlow();

  /// Arus [transactions] pada bulan [month]. Transaksi di luar bulan itu
  /// diabaikan, jadi hasil `listTransactionsInMonth` maupun riwayat penuh
  /// sama-sama boleh diberikan.
  CashFlow call(Iterable<Transaction> transactions, {required DateTime month}) {
    var income = 0;
    var expense = 0;
    for (final transaction in transactions) {
      if (transaction.date.year != month.year || transaction.date.month != month.month) continue;
      switch (transaction) {
        case IncomeTransaction():
          income += transaction.amount;
        case ExpenseTransaction():
          expense += transaction.amount;
        case TransferTransaction():
          break;
      }
    }
    return CashFlow(income: income, expense: expense);
  }
}
