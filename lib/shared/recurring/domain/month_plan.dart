import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/recurring/domain/occurrence_status.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Satu pos anggaran **pengeluaran** yang terhitung di bulan itu, dalam sen.
/// Pos transfer (setoran tabungan) tidak diberikan: transfer tidak
/// mengurangi uang nganggur (KT-R14, aturan 7).
typedef BudgetPlanLine = ({String itemId, String? key, int planned, int spent});

/// Rencana satu bulan keuangan (RECURRING_AND_FORECAST §7.2, §7.2a; ADR-035
/// §3.5). **Uang nganggur bukan saldo**: ini aliran rencana bulan itu, bukan
/// isi dompet.
final class MonthPlan extends Equatable {
  /// Membuat [MonthPlan].
  const MonthPlan({
    required this.plannedIncome,
    required this.recordedIncome,
    required this.plannedRecurringOut,
    required this.recordedRecurringOut,
    required this.budgetPlanned,
    required this.budgetSpent,
    required this.unplannedOut,
    required this.unplannedIn,
    required this.budgetOverrun,
    required this.recurringDifference,
    required this.moved,
    required this.hasEstimate,
  });

  /// Kemunculan pemasukan rutin yang tidak dilewati, nominal rencana.
  final int plannedIncome;

  /// Bagian [plannedIncome] yang sudah tercatat, nominal tercatat.
  final int recordedIncome;

  /// Kemunculan pengeluaran rutin yang tidak dilewati dan tidak tertaut pos
  /// anggaran (invarian 17), nominal rencana.
  final int plannedRecurringOut;

  /// Bagian [plannedRecurringOut] yang sudah tercatat, nominal tercatat.
  final int recordedRecurringOut;

  /// Rencana anggaran bulan itu.
  final int budgetPlanned;

  /// Terpakai anggaran bulan itu.
  final int budgetSpent;

  /// Pengeluaran tercatat di luar rutin dan anggaran.
  final int unplannedOut;

  /// Pemasukan tercatat di luar rutin (bonus, refund).
  final int unplannedIn;

  /// Terpakai di atas rencana, dijumlah per pos.
  final int budgetOverrun;

  /// Selisih nominal rutin tercatat dari rencananya: positif bila
  /// pemasukan lebih besar atau pengeluaran lebih kecil.
  final int recurringDifference;

  /// Transfer rutin bulan itu: ditampilkan terpisah, tidak mengurangi apa pun.
  final int moved;

  /// Ada nominal kira-kira yang belum tercatat.
  final bool hasEstimate;

  /// Uang nganggur rencana: pemasukan − rutin keluar − anggaran (§7.2).
  int get planned => plannedIncome - plannedRecurringOut - budgetPlanned;

  /// Sisa uang nganggur (§7.2a): rencana dikurangi belanja di luar rencana
  /// dan kelebihan pos, ditambah pemasukan di luar rencana, ± selisih rutin.
  int get remaining => planned - unplannedOut - budgetOverrun + unplannedIn + recurringDifference;

  @override
  List<Object?> get props => [
    plannedIncome,
    recordedIncome,
    plannedRecurringOut,
    recordedRecurringOut,
    budgetPlanned,
    budgetSpent,
    unplannedOut,
    unplannedIn,
    budgetOverrun,
    recurringDifference,
    moved,
    hasEstimate,
  ];
}

/// Rencana bulan `from <= d < until` per [today].
///
/// [transactions] adalah transaksi bertanggal di bulan itu; [budgetLines]
/// pos pengeluaran anggaran yang periodenya jatuh di bulan itu. Rutin yang
/// dijeda hanya menyumbang kemunculan yang sudah tercatat.
MonthPlan monthPlan(
  Iterable<RecurringRule> rules, {
  required DateTime from,
  required DateTime until,
  required DateTime today,
  required Iterable<Transaction> transactions,
  required Iterable<BudgetPlanLine> budgetLines,
}) {
  var plannedIncome = 0;
  var recordedIncome = 0;
  var plannedOut = 0;
  var recordedOut = 0;
  var difference = 0;
  var moved = 0;
  var hasEstimate = false;
  final lines = budgetLines.toList();
  final lineKeys = {
    for (final line in lines)
      if (line.key case final key?) key,
  };
  // Kemunculan rutin tertaut pos per kunci pos (ADR-036 §3.4).
  final linked = <String, int>{};
  for (final rule in rules) {
    // Invarian 17/21: rutin tertaut pos yang ada di bulan ini terhitung di
    // pos itu, dengan rencana pos = max(rencana, Σ kemunculan tertaut).
    final key = rule.budgetItemKey;
    final inBudget = rule.kind == RecurringKind.expense && key != null && lineKeys.contains(key);
    final occurrences = occurrenceStatusesOf(
      rule,
      from: from,
      until: until,
      today: today,
      transactions: transactions,
    );
    for (final o in occurrences) {
      if (o.status == OccurrenceStatus.skipped || o.status == OccurrenceStatus.paused) continue;
      final recorded = o.transaction;
      if (inBudget) {
        linked[key] = (linked[key] ?? 0) + (recorded?.amount ?? rule.amount);
        continue;
      }
      if (recorded == null && rule.amountMode == RecurringAmountMode.estimated) hasEstimate = true;
      switch (rule.kind) {
        case RecurringKind.income:
          plannedIncome += rule.amount;
          if (recorded != null) {
            recordedIncome += recorded.amount;
            difference += recorded.amount - rule.amount;
          }
        case RecurringKind.expense:
          plannedOut += rule.amount;
          if (recorded != null) {
            recordedOut += recorded.amount;
            difference -= recorded.amount - rule.amount;
          }
        case RecurringKind.transfer:
          moved += rule.amount;
      }
    }
  }

  int plannedOf(BudgetPlanLine line) {
    final fromRules = line.key == null ? 0 : linked[line.key] ?? 0;
    return line.planned > fromRules ? line.planned : fromRules;
  }

  final budgetItems = {for (final line in lines) line.itemId};
  // Transaksi yang rutinnya sudah dihapus tidak lagi disumbang rutin mana
  // pun, jadi dihitung di luar rencana (T-15.18).
  final ruleIds = {for (final rule in rules) rule.id};
  var unplannedOut = 0;
  var unplannedIn = 0;
  for (final t in transactions) {
    if (ruleIds.contains(t.recurrence?.ruleId) || t.date.isBefore(from) || !t.date.isBefore(until)) continue;
    switch (t) {
      case ExpenseTransaction(:final budgetItemId) when budgetItemId == null || !budgetItems.contains(budgetItemId):
        unplannedOut += t.amount;
      case IncomeTransaction():
        unplannedIn += t.amount;
      case ExpenseTransaction() || TransferTransaction():
        break;
    }
  }

  return MonthPlan(
    plannedIncome: plannedIncome,
    recordedIncome: recordedIncome,
    plannedRecurringOut: plannedOut,
    recordedRecurringOut: recordedOut,
    budgetPlanned: lines.fold(0, (sum, line) => sum + plannedOf(line)),
    budgetSpent: lines.fold(0, (sum, line) => sum + line.spent),
    unplannedOut: unplannedOut,
    unplannedIn: unplannedIn,
    budgetOverrun: lines.fold(
      0,
      (sum, line) => sum + (line.spent > plannedOf(line) ? line.spent - plannedOf(line) : 0),
    ),
    recurringDifference: difference,
    moved: moved,
    hasEstimate: hasEstimate,
  );
}
