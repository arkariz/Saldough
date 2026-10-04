import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/recurring/domain/occurrence_recording.dart';
import 'package:saldough/shared/recurring/domain/occurrence_status.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Satu catatan otomatis (ADR-037 §3.2). Disimpan juga sesudah dibatalkan
/// ([undone]) supaya kemunculan itu tidak dicatat otomatis lagi.
final class AutoRecordEntry extends Equatable {
  /// Membuat [AutoRecordEntry].
  const AutoRecordEntry({
    required this.transactionId,
    required this.ruleId,
    required this.ruleName,
    required this.occurrenceDate,
    required this.recordedAt,
    this.undone = false,
  });

  /// Transaksi yang dicatat.
  final String transactionId;

  /// Rutinnya.
  final String ruleId;

  /// Nama rutin saat dicatat.
  final String ruleName;

  /// Tanggal kemunculan (tanpa jam).
  final DateTime occurrenceDate;

  /// Kapan dicatat.
  final DateTime recordedAt;

  /// Sudah dibatalkan pengguna.
  final bool undone;

  /// Salinan yang ditandai dibatalkan.
  AutoRecordEntry markUndone() => AutoRecordEntry(
    transactionId: transactionId,
    ruleId: ruleId,
    ruleName: ruleName,
    occurrenceDate: occurrenceDate,
    recordedAt: recordedAt,
    undone: true,
  );

  @override
  List<Object?> get props => [transactionId, ruleId, ruleName, occurrenceDate, recordedAt, undone];
}

/// Log catat otomatis di `recurring/auto_record_log`.
abstract interface class AutoRecordLogRepository {
  /// Entri yang masih disimpan per [now].
  Future<Either<Failure, List<AutoRecordEntry>>> list(DateTime now);

  /// Menambah entri.
  Future<Either<Failure, Unit>> add(List<AutoRecordEntry> entries);

  /// Menandai entri [transactionId] dibatalkan.
  Future<Either<Failure, Unit>> markUndone(String transactionId);
}

/// Kemunculan yang dicatat otomatis per [today] (ADR-037 §3.2): rutin
/// aktif bernominal tetap dengan `autoRecord`, kemunculan menunggu atau
/// terlewat sejak [windowStart], autodebet paling cepat H+1, belum pernah
/// dicatat otomatis ([logged]), dan tanpa transaksi mirip (ragu = tidak).
List<(RecurringRule, DateTime)> dueAutoRecords(
  Iterable<RecurringRule> rules, {
  required DateTime windowStart,
  required DateTime today,
  required Iterable<Transaction> transactions,
  required Set<(String, DateTime)> logged,
}) {
  final day = DateTime(today.year, today.month, today.day);
  final due = <(RecurringRule, DateTime)>[];
  for (final rule in rules) {
    if (!rule.autoRecord || rule.isPaused || rule.amountMode != RecurringAmountMode.fixed) continue;
    final autoDebit = rule.effectivePaymentMode == RecurringPaymentMode.autoDebit;
    for (final o in occurrenceStatusesOf(
      rule,
      from: windowStart,
      until: DateTime(day.year, day.month, day.day + 1),
      today: day,
      transactions: transactions,
    )) {
      if (o.status != OccurrenceStatus.pending && o.status != OccurrenceStatus.missed) continue;
      if (autoDebit && !o.date.isBefore(day)) continue;
      if (logged.contains((rule.id, o.date))) continue;
      if (matchCandidates(rule, o.date, transactions).isNotEmpty) continue;
      due.add((rule, o.date));
    }
  }
  return due;
}
