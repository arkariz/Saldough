import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Tanggal gajian yang disarankan kartu tawaran di Rencana › Bulan ini
/// (FEATURE_DISCOVERY §6.2), atau `null` bila kartu tidak tampil.
///
/// Kartu hanya menyarankan (FINANCIAL_PERIOD P-1–P-11 tidak berubah) dan
/// tampil bila: jadwal masih bawaan, pengguna belum pernah mengubah awal bulan
/// sendiri, kartu belum dijawab, dan ada pemasukan berkategori Gaji
/// ([salaryCategoryIds]) bertanggal 2–28 di [transactions]. Yang dipakai
/// pemasukan Gaji terbaru; pembayaran freelance tidak dihitung.
int? paydayOfferDay(
  Iterable<Transaction> transactions, {
  required Set<String> salaryCategoryIds,
  required FinancialMonthSchedule schedule,
  required FinancialMonthOffer offer,
}) {
  if (offer.changedByUser || offer.paydayCardAnswered) return null;
  if (schedule != FinancialMonthSchedule.initial) return null;
  IncomeTransaction? latest;
  for (final transaction in transactions) {
    if (transaction is! IncomeTransaction || transaction.isFreelancePayment) continue;
    final categoryId = transaction.categoryId;
    if (categoryId == null || !salaryCategoryIds.contains(categoryId)) continue;
    if (transaction.date.day < 2 || transaction.date.day > FinancialMonthStart.maxDay) continue;
    if (latest == null || transaction.date.isAfter(latest.date)) latest = transaction;
  }
  return latest?.date.day;
}
