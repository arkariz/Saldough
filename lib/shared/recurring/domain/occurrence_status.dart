import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/recurring/domain/occurrences.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Status satu kemunculan rutin, **diturunkan**, tidak disimpan (ADR-035
/// §3.2).
enum OccurrenceStatus {
  /// Ada transaksi yang menautkan `(ruleId, tanggal)`.
  recorded,

  /// Tanggalnya ada di `skippedDates`.
  skipped,

  /// Sudah tiba, belum dicatat atau dilewati, dan merupakan kemunculan
  /// terbaru yang sudah tiba.
  pending,

  /// Seperti [pending], tetapi sudah ada kemunculan yang lebih baru.
  missed,

  /// Belum tiba.
  upcoming,

  /// Sudah tiba dan belum dicatat, tetapi rutinnya dijeda: tidak menunggu.
  paused,
}

/// Satu kemunculan [rule] pada [date] beserta statusnya.
final class Occurrence extends Equatable {
  /// Membuat [Occurrence].
  const Occurrence({required this.rule, required this.date, required this.status, this.transaction});

  /// Rutinnya.
  final RecurringRule rule;

  /// Tanggal menurut jadwal (tanpa jam).
  final DateTime date;

  /// Status turunan.
  final OccurrenceStatus status;

  /// Transaksi yang mencatatnya, bila [OccurrenceStatus.recorded].
  final Transaction? transaction;

  @override
  List<Object?> get props => [rule.id, date, status, transaction];
}

/// Kemunculan [rule] di rentang `from <= d < until` beserta statusnya per
/// [today].
///
/// [transactions] cukup berisi dokumen bulan yang mencakup rentang itu
/// (ADR-012); transaksi tanpa `recurrence` atau milik rutin lain diabaikan.
/// Menghapus transaksinya membuat kemunculan kembali menunggu atau terlewat,
/// karena statusnya hanya dibaca dari tautan.
List<Occurrence> occurrenceStatusesOf(
  RecurringRule rule, {
  required DateTime from,
  required DateTime until,
  required DateTime today,
  required Iterable<Transaction> transactions,
}) {
  final day = DateTime(today.year, today.month, today.day);
  final recordedBy = <DateTime, Transaction>{
    for (final t in transactions)
      if (t.recurrence case final link? when link.ruleId == rule.id) link.occurrenceDate: t,
  };
  final arrived = occurrencesOf(
    rule,
    from: rule.schedule.anchorDate,
    until: DateTime(day.year, day.month, day.day + 1),
  );
  final latestArrived = arrived.isEmpty ? null : arrived.last;

  return [
    for (final date in occurrencesOf(rule, from: from, until: until))
      Occurrence(
        rule: rule,
        date: date,
        transaction: recordedBy[date],
        status: switch (date) {
          _ when recordedBy.containsKey(date) => OccurrenceStatus.recorded,
          _ when rule.skippedDates.contains(date) => OccurrenceStatus.skipped,
          _ when date.isAfter(day) => OccurrenceStatus.upcoming,
          _ when rule.isPaused => OccurrenceStatus.paused,
          _ when date == latestArrived => OccurrenceStatus.pending,
          _ => OccurrenceStatus.missed,
        },
      ),
  ];
}

/// Berapa hari sesudah tanggalnya autodebet yang belum tercatat atau tertaut
/// dianggap belum terlihat (E3, ADR-037 §3.1).
const unseenAfterDays = 2;

/// [occurrence] adalah autodebet yang sudah [unseenAfterDays] hari lewat
/// tanpa tercatat, tertaut, atau dilewati, dan tidak sedang ditunda lewat
/// "Belum terjadi". Turunan, tidak disimpan; bayar sendiri tidak pernah.
bool isUnseen(Occurrence occurrence, {required DateTime today}) {
  final rule = occurrence.rule;
  if (occurrence.status != OccurrenceStatus.pending && occurrence.status != OccurrenceStatus.missed) return false;
  if (rule.effectivePaymentMode != RecurringPaymentMode.autoDebit) return false;
  final day = DateTime(today.year, today.month, today.day);
  final date = occurrence.date;
  if (day.isBefore(DateTime(date.year, date.month, date.day + unseenAfterDays))) return false;
  final snoozed = rule.snoozedUntil;
  return snoozed == null || !day.isBefore(DateTime(snoozed.year, snoozed.month, snoozed.day));
}
