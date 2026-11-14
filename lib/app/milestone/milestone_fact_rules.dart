import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_def.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Paling banyak berapa periode tertutup ke belakang yang diperiksa untuk
/// stempel Rutin tak terlewat (menjaga biaya evaluasi; satu periode yang
/// memenuhi sudah cukup, G-3).
const maxClosedPeriodsChecked = 24;

/// Minimal transaksi pemasukan dan pengeluaran di periode tertutup agar
/// bisa disebut rapi (GAMIFICATION §5; pencegah kebetulan, G-2).
const tidyPeriodMinTransactions = 3;

/// Himpunan [MilestoneFact] yang benar sekarang, dihitung murni dari data
/// (ADR-046 §3.3). Tidak menyimpan apa pun dan tidak membaca jam global.
///
/// Aturan keanggotaan periode sama dengan Analisis: `periodDateOf` lalu
/// `financialPeriodOf`. Periode **tertutup** bila [today] sudah mencapai
/// `end` (tanggal awal periode berikutnya).
Set<MilestoneFact> milestoneFactsFrom({
  required List<Wallet> wallets,
  required List<Transaction> transactions,
  required List<RecurringRule> rules,
  required FinancialMonthSchedule schedule,
  required DateTime today,
  required bool backupDone,
  required bool inboxCleared,
}) {
  final day = DateTime(today.year, today.month, today.day);
  return {
    if (wallets.any((w) => w.isActive)) MilestoneFact.walletExists,
    if (transactions.isNotEmpty) MilestoneFact.recordExists,
    if (transactions.any((t) => _budgetItemOf(t) != null)) MilestoneFact.budgetItemLinked,
    if (transactions.any((t) => t is IncomeTransaction && t.isFreelancePayment)) MilestoneFact.freelancePaid,
    if (backupDone) MilestoneFact.backupDone,
    if (inboxCleared) MilestoneFact.inboxCleared,
    if (_hasTidyClosedPeriod(transactions, schedule, day)) MilestoneFact.tidyPeriodClosed,
    if (_hasRecurringClearClosedPeriod(rules, transactions, schedule, day)) MilestoneFact.recurringClearClosed,
  };
}

String? _budgetItemOf(Transaction t) => switch (t) {
  ExpenseTransaction(:final budgetItemId) => budgetItemId,
  TransferTransaction(:final budgetItemId) => budgetItemId,
  IncomeTransaction() => null,
};

bool _isClosed(FinancialPeriod period, DateTime day) => !day.isBefore(period.end);

/// Ada satu periode tertutup dengan ≥[tidyPeriodMinTransactions] pemasukan dan
/// pengeluaran dan tanpa satu pun yang tanpa kategori. Transfer tidak dihitung;
/// pemasukan freelance tanpa kategori juga tidak dianggap tanpa kategori
/// (sama seperti Analisis).
bool _hasTidyClosedPeriod(List<Transaction> transactions, FinancialMonthSchedule schedule, DateTime day) {
  final counts = <DateTime, int>{};
  final untidy = <DateTime>{};
  for (final t in transactions) {
    if (t is TransferTransaction) continue;
    final period = financialPeriodOf(periodDateOf(t), schedule);
    if (!_isClosed(period, day)) continue;
    counts[period.start] = (counts[period.start] ?? 0) + 1;
    final categorized = t.categoryId != null || (t is IncomeTransaction && t.isFreelancePayment);
    if (!categorized) untidy.add(period.start);
  }
  return counts.entries.any((e) => e.value >= tidyPeriodMinTransactions && !untidy.contains(e.key));
}

/// Ada satu periode tertutup dengan ≥1 kemunculan rutin (yang tidak sedang
/// dijeda) dan tanpa satu pun yang masih Menunggu atau Terlewat. Tercatat,
/// tertaut, dan dilewati dihitung selesai.
bool _hasRecurringClearClosedPeriod(
  List<RecurringRule> rules,
  List<Transaction> transactions,
  FinancialMonthSchedule schedule,
  DateTime day,
) {
  if (rules.isEmpty) return false;
  final earliest = rules.map((r) => r.schedule.anchorDate).reduce((a, b) => a.isBefore(b) ? a : b);
  var period = financialPeriodOf(day, schedule);
  for (var i = 0; i < maxClosedPeriodsChecked; i++) {
    // Mundur satu periode: hari terakhir periode sebelumnya.
    period = financialPeriodOf(DateTime(period.start.year, period.start.month, period.start.day - 1), schedule);
    if (period.end.isBefore(earliest)) return false;
    if (!_isClosed(period, day)) continue;
    final occurrences = [
      for (final rule in rules)
        ...occurrenceStatusesOf(
          rule,
          from: period.start,
          until: period.end,
          today: day,
          transactions: transactions,
        ).where((o) => o.status != OccurrenceStatus.paused),
    ];
    if (occurrences.isEmpty) continue;
    final open = occurrences.any((o) => o.status == OccurrenceStatus.pending || o.status == OccurrenceStatus.missed);
    if (!open) return true;
  }
  return false;
}
