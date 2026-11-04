import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Penutup bersama transaksi dari notifikasi (ADR-044 §3.2): sesudah
/// transaksi disusun dari draf dan sebelum disimpan, tautkan ke kemunculan
/// rutin yang cocok dan bebankan ke pos anggaran periodenya. Status
/// kemunculan dan progres anggaran diturunkan dari tautan dan `budgetItemId`,
/// jadi keduanya tidak butuh langkah hitung ulang.
///
/// Pos hanya mengikuti rutin: pengeluaran bebas tanpa rutin tidak diisi di
/// sini (saran pos adalah E2, B-86).
final class CaptureFinalizer {
  /// Membuat [CaptureFinalizer]. Tanpa [budgetItems], tautan rutin tetap dibuat
  /// tetapi pos tidak diisi.
  const CaptureFinalizer({this.budgetItems});

  /// Katalog pos anggaran lintas fitur; `null` di platform atau uji tanpa
  /// anggaran.
  final BudgetItemCatalog? budgetItems;

  /// [transaction] dengan tautan ke [match] (bila ada) dan, untuk pengeluaran
  /// tanpa pos, pos periode kemunculan itu bila rutinnya tertaut ke pos.
  /// Tanpa [match], [transaction] dikembalikan apa adanya.
  Future<Transaction> finalize(
    Transaction transaction, {
    OccurrenceMatch? match,
    RecurrenceLinkedBy linkedBy = RecurrenceLinkedBy.auto,
  }) async {
    if (match == null) return transaction;
    final linked = transaction.withRecurrence(match.link(linkedBy: linkedBy));
    if (linked is! ExpenseTransaction || linked.budgetItemId != null) return linked;
    if (match.rule.budgetItemKey == null) return linked;
    final options = (await budgetItems?.listOptions())?.getOrElse((_) => const []) ?? const <BudgetItemOption>[];
    final itemId = budgetItemForOccurrence(match.rule, match.date, options);
    return itemId == null ? linked : linked.copyWith(budgetItemId: itemId);
  }

  /// Kebalikan [finalize] untuk Lepaskan (tautan otomatis yang keliru):
  /// kemunculan kembali menunggu dan pengeluaran tidak lagi dibebankan ke pos
  /// yang datang dari tautan itu. Saldo tidak berubah.
  static Transaction release(Transaction transaction) {
    final released = transaction.withRecurrence(null);
    if (released is! ExpenseTransaction || released.budgetItemId == null) return released;
    // `copyWith` tidak bisa mengosongkan pos, jadi buat ulang.
    return ExpenseTransaction(
      id: released.id,
      date: released.date,
      amount: released.amount,
      note: released.note,
      sourceIconId: released.sourceIconId,
      categoryId: released.categoryId,
      walletId: released.walletId,
    );
  }
}
