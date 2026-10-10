import 'package:saldough/shared/transaction/domain/transaction.dart';

/// Selisih hari terjauh antara tanggal transaksi dan kemunculan rutinnya
/// yang masih dihitung ke periode kemunculan (FINANCIAL_PERIOD P-4).
const periodAttributionDays = 7;

/// Tanggal periode [transaction] (ADR-038 §3.5, FINANCIAL_PERIOD P-4): tanggal
/// kemunculan rutin bila tertaut dan selisihnya dengan `date` paling banyak
/// [periodAttributionDays] hari, selain itu `date`. Hanya untuk keanggotaan
/// periode (Rencana, Beranda, Analisis, penyaring periode Riwayat); saldo,
/// perkiraan harian, dan partisi penyimpanan tetap memakai `date`.
DateTime periodDateOf(Transaction transaction) =>
    periodDateFor(transaction.date, transaction.recurrence?.occurrenceDate);

/// [periodDateOf] untuk transaksi bertanggal [date] yang tertaut kemunculan
/// [occurrence] (`null` = tidak tertaut), mis. isian CATAT yang belum
/// menjadi transaksi.
DateTime periodDateFor(DateTime date, DateTime? occurrence) {
  if (occurrence == null) return date;
  final gap = DateTime.utc(date.year, date.month, date.day)
      .difference(DateTime.utc(occurrence.year, occurrence.month, occurrence.day))
      .inDays
      .abs();
  return gap <= periodAttributionDays ? occurrence : date;
}
