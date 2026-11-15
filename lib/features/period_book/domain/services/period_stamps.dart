import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';
import 'package:saldough/features/period_book/domain/services/closed_periods.dart';

/// Id stempel periode (kosakata B-94, GAMIFICATION §5) yang bisa tercetak di
/// sampul buku.
const periodStampTidy = 'period_tidy';

/// Lihat [periodStampTidy].
const periodStampRecurringClear = 'recurring_clear';

/// Stempel yang **diraih di periode ini** dan tercetak di sampulnya (BP-13,
/// GAMIFICATION): hanya dua stempel periode, dengan syarat yang sama dengan mesin
/// tonggak tetapi untuk satu periode.
///
/// - Periode rapi: ≥[periodCardMinTransactions] transaksi dan tidak ada yang tanpa
///   kategori (transfer dan pemasukan freelance tanpa kategori tidak dihitung).
/// - Rutin tak terlewat: ada rutin dan semuanya beres (tanpa Menunggu/Terlewat).
///
/// Murni. Yang sudah tercetak tidak dicabut (G-1): pemanggil menggabungkannya
/// dengan `PeriodBookMemory.stampsOf`.
List<String> periodStampsOf(PeriodBookContent content) => [
  if (content.period.transactionCount >= periodCardMinTransactions && content.uncategorizedCount == 0)
    periodStampTidy,
  if (content.plan case final plan? when plan.hasRoutine && plan.open == 0) periodStampRecurringClear,
];
