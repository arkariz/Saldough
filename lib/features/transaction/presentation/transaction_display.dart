import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Judul tampilan sebuah transaksi: kategori kalau ada, kalau tidak catatan,
/// kalau tidak juga "Tanpa judul". Dipakai bersama kartu daftar dan layar
/// rincian supaya keduanya tidak pernah menamai transaksi yang sama berbeda.
String transactionTitle(Transaction transaction) {
  final category = transaction.categoryKey;
  if (category != null && category.isNotEmpty) return category;
  if (transaction.note.isNotEmpty) return transaction.note;
  return t.transaction.untitledTransaction;
}

/// Jam `HH:mm` dari [date].
String transactionTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
