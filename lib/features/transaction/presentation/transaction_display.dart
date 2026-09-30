import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Judul tampilan sebuah transaksi: kategori kalau ada, kalau tidak catatan,
/// kalau tidak juga "Tanpa judul". Dipakai bersama kartu daftar dan layar
/// rincian supaya keduanya tidak pernah menamai transaksi yang sama berbeda.
String transactionTitle(Transaction transaction) {
  final category = ActiveCategories.byId(transaction.categoryId);
  if (category != null) return category.name;
  if (transaction.note.isNotEmpty) return transaction.note;
  return t.transaction.untitledTransaction;
}

/// Jam `HH:mm` dari [date].
String transactionTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
