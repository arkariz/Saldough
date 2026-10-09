import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Judul tampilan sebuah transaksi: catatan kalau ada, kalau tidak kategori,
/// kalau tidak juga jenisnya ("Transfer", "Pengeluaran", "Pemasukan").
/// Dipakai bersama kartu daftar dan layar rincian supaya keduanya tidak
/// pernah menamai transaksi yang sama berbeda.
String transactionTitle(Transaction transaction) {
  // Pola Daftar design system: catatan dulu, nama kategori bila kosong.
  if (transaction.note.isNotEmpty) return transaction.note;
  final category = ActiveCategories.byId(transaction.categoryId);
  if (category != null) return category.name;
  return switch (transaction) {
    ExpenseTransaction() => t.record.kindExpense,
    IncomeTransaction() => t.record.kindIncome,
    TransferTransaction() => t.record.kindTransfer,
  };
}

/// Jam bertitik `HH.mm` dari [date] (design system bagian Konten).
String transactionTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')}';
