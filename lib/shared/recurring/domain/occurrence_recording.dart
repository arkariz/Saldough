import 'package:saldough/shared/recurring/domain/recurring_rule.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Transaksi yang mencatat kemunculan [occurrence] dari [rule] (ADR-034
/// §3.3): isiannya dari rutin, tanggalnya **tanggal kemunculan** (E11, bukan
/// hari ini) dengan jam dari [now], dan tertaut ke kemunculan itu.
/// [amount] menggantikan nominal rutin bila diisi.
Transaction transactionForOccurrence(
  RecurringRule rule,
  DateTime occurrence, {
  required String id,
  required DateTime now,
  int? amount,
}) {
  final date = DateTime(occurrence.year, occurrence.month, occurrence.day, now.hour, now.minute);
  final link = RecurrenceLink(ruleId: rule.id, occurrenceDate: occurrence);
  final value = amount ?? rule.amount;
  return switch (rule.kind) {
    RecurringKind.income => IncomeTransaction(
      id: id,
      date: date,
      amount: value,
      note: rule.note,
      walletId: rule.walletId,
      categoryId: rule.categoryId,
      recurrence: link,
    ),
    RecurringKind.expense => ExpenseTransaction(
      id: id,
      date: date,
      amount: value,
      note: rule.note,
      walletId: rule.walletId,
      categoryId: rule.categoryId,
      recurrence: link,
    ),
    RecurringKind.transfer => TransferTransaction(
      id: id,
      date: date,
      amount: value,
      note: rule.note,
      fromWalletId: rule.walletId,
      toWalletId: rule.toWalletId!,
      recurrence: link,
    ),
  };
}

/// Selisih hari terjauh antara transaksi dan kemunculan yang dianggap cocok
/// (ADR-034 §3.4).
const matchWindowDays = 3;

/// Transaksi di [transactions] yang mungkin sudah mencatat kemunculan
/// [occurrence] dari [rule] (ADR-034 §3.4, E4): jenis dan dompetnya sama,
/// nominalnya persis (rutin tetap) atau dalam ±10% (rutin kira-kira),
/// tanggalnya dalam ±3 hari, dan belum tertaut ke rutin mana pun.
List<Transaction> matchCandidates(RecurringRule rule, DateTime occurrence, Iterable<Transaction> transactions) {
  final day = DateTime(occurrence.year, occurrence.month, occurrence.day);
  bool amountMatches(int amount) => rule.amountMode == RecurringAmountMode.fixed
      ? amount == rule.amount
      : (amount - rule.amount).abs() * 10 <= rule.amount;
  bool walletMatches(Transaction t) => switch ((rule.kind, t)) {
    (RecurringKind.income, IncomeTransaction(:final walletId)) => walletId == rule.walletId,
    (RecurringKind.expense, ExpenseTransaction(:final walletId)) => walletId == rule.walletId,
    (RecurringKind.transfer, TransferTransaction(:final fromWalletId, :final toWalletId)) =>
      fromWalletId == rule.walletId && toWalletId == rule.toWalletId,
    _ => false,
  };
  return [
    for (final t in transactions)
      if (t.recurrence == null &&
          walletMatches(t) &&
          amountMatches(t.amount) &&
          DateTime(t.date.year, t.date.month, t.date.day).difference(day).inDays.abs() <= matchWindowDays)
        t,
  ];
}

/// E5 (KT-R12, untuk rutin): nominal [typed] ≥5× atau ≤⅕ dari [usual]. Sen.
bool isUnusualAmount({required int usual, required int typed}) =>
    usual > 0 && (typed >= usual * 5 || typed * 5 <= usual);

/// E11: tanggal transaksi lebih dari 7 hari dari kemunculannya.
bool isFarFromOccurrence(DateTime date, DateTime occurrence) =>
    DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(occurrence.year, occurrence.month, occurrence.day)).inDays.abs() >
    7;
