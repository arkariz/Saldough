import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/recurring/domain/occurrence_recording.dart';
import 'package:saldough/shared/recurring/domain/occurrence_status.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Satu kemunculan yang cocok dengan sebuah transaksi atau draf.
final class OccurrenceMatch extends Equatable {
  /// Membuat [OccurrenceMatch].
  const OccurrenceMatch({required this.rule, required this.date, required this.exact});

  /// Rutinnya.
  final RecurringRule rule;

  /// Tanggal kemunculan.
  final DateTime date;

  /// Rutin bernominal tetap dan nominalnya persis: boleh ditautkan otomatis
  /// (KT-R11). Rutin kira-kira yang masuk ±10% hanya disarankan.
  final bool exact;

  /// Tautan untuk transaksi yang cocok.
  RecurrenceLink link({RecurrenceLinkedBy linkedBy = RecurrenceLinkedBy.user}) =>
      RecurrenceLink(ruleId: rule.id, occurrenceDate: date, linkedBy: linkedBy);

  @override
  List<Object?> get props => [rule.id, date, exact];
}

/// Kemunculan yang cocok dengan transaksi berjenis [kind] di dompet
/// [walletId] (ke [toWalletId] untuk transfer), bernominal [amount], pada
/// [date] (ADR-035 §3.4): rutin tidak dijeda, jenis dan dompet sama,
/// nominal persis (tetap) atau ±10% (kira-kira), tanggal dalam ±3 hari, dan
/// kemunculannya belum tercatat atau dilewati. [transactions] memuat bulan
/// di sekitar [date] untuk membaca yang sudah tercatat.
List<OccurrenceMatch> occurrenceCandidates({
  required RecurringKind kind,
  required String walletId,
  required int amount,
  required DateTime date,
  required Iterable<RecurringRule> rules,
  required Iterable<Transaction> transactions,
  String? toWalletId,
}) {
  final day = DateTime(date.year, date.month, date.day);
  final from = DateTime(day.year, day.month, day.day - matchWindowDays);
  final until = DateTime(day.year, day.month, day.day + matchWindowDays + 1);
  final matches = <OccurrenceMatch>[];
  for (final rule in rules) {
    if (rule.isPaused || rule.kind != kind || rule.walletId != walletId) continue;
    if (kind == RecurringKind.transfer && rule.toWalletId != toWalletId) continue;
    final fixed = rule.amountMode == RecurringAmountMode.fixed;
    final amountOk = fixed ? amount == rule.amount : (amount - rule.amount).abs() * 10 <= rule.amount;
    if (!amountOk) continue;
    for (final o in occurrenceStatusesOf(rule, from: from, until: until, today: until, transactions: transactions)) {
      if (o.status == OccurrenceStatus.recorded || o.status == OccurrenceStatus.skipped) continue;
      matches.add(OccurrenceMatch(rule: rule, date: o.date, exact: fixed));
    }
  }
  return matches;
}

/// Jendela pencocokan rutin yang terikat pola notifikasi (ADR-042 §3.4).
const boundMatchWindowDays = 7;

/// Kemunculan [rule] yang cocok dengan notifikasi yang sudah dikenali
/// polanya milik [rule] (ADR-042 §3.4): rutin tidak dijeda, jenis, dompet,
/// dan (untuk transfer) dompet tujuan sama, nominal persis (tetap) atau ±10%
/// (kira-kira, `exact` false), dan **tepat satu** kemunculan terbuka dalam
/// ±[boundMatchWindowDays] hari dari [date]. `null` bila salah satu tidak
/// terpenuhi -- tidak pernah menebak.
OccurrenceMatch? matchBoundOccurrence(
  RecurringRule rule, {
  required RecurringKind kind,
  required String walletId,
  required int amount,
  required DateTime date,
  required Iterable<Transaction> transactions,
  String? toWalletId,
}) {
  if (rule.isPaused || rule.kind != kind || rule.walletId != walletId) return null;
  if (kind == RecurringKind.transfer && rule.toWalletId != toWalletId) return null;
  final fixed = rule.amountMode == RecurringAmountMode.fixed;
  final amountOk = fixed ? amount == rule.amount : (amount - rule.amount).abs() * 10 <= rule.amount;
  if (!amountOk) return null;
  final day = DateTime(date.year, date.month, date.day);
  final open = [
    for (final o in occurrenceStatusesOf(
      rule,
      from: DateTime(day.year, day.month, day.day - boundMatchWindowDays),
      until: DateTime(day.year, day.month, day.day + boundMatchWindowDays + 1),
      today: day,
      transactions: transactions,
    ))
      if (o.status != OccurrenceStatus.recorded && o.status != OccurrenceStatus.skipped) o,
  ];
  if (open.length != 1) return null;
  return OccurrenceMatch(rule: rule, date: open.single.date, exact: fixed);
}

/// Kecocokan tunggal untuk [transaction], atau `null` bila tidak ada, ada
/// lebih dari satu kandidat, atau transaksinya sudah tertaut. Dua kandidat
/// selalu ditanyakan, tidak ditebak (ADR-035 §3.4).
OccurrenceMatch? matchOccurrences(
  Transaction transaction, {
  required Iterable<RecurringRule> rules,
  required Iterable<Transaction> transactions,
}) {
  if (transaction.recurrence != null) return null;
  final (kind, wallet, to) = switch (transaction) {
    IncomeTransaction(:final walletId) => (RecurringKind.income, walletId, null),
    ExpenseTransaction(:final walletId) => (RecurringKind.expense, walletId, null),
    TransferTransaction(:final fromWalletId, :final toWalletId) => (RecurringKind.transfer, fromWalletId, toWalletId),
  };
  final candidates = occurrenceCandidates(
    kind: kind,
    walletId: wallet,
    toWalletId: to,
    amount: transaction.amount,
    date: transaction.date,
    rules: rules,
    transactions: transactions,
  );
  return candidates.length == 1 ? candidates.single : null;
}
