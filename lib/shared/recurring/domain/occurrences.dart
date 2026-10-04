import 'package:saldough/shared/recurring/domain/recurring_rule.dart';

/// Tanggal-tanggal kemunculan [rule] di rentang `from <= d < until`, urut
/// naik, mengikuti jadwal dan akhir rutinnya (ADR-035 §3.1).
///
/// Murni jadwal: tidak memperhatikan `isPaused` maupun `skippedDates`, yang
/// dibaca saat menurunkan status kemunculan.
List<DateTime> occurrencesOf(RecurringRule rule, {required DateTime from, required DateTime until}) {
  final start = DateTime(from.year, from.month, from.day);
  final result = <DateTime>[];
  for (var n = 0; ; n++) {
    final date = _occurrenceWithinEnd(rule, n);
    if (date == null || !date.isBefore(until)) break;
    if (!date.isBefore(start)) result.add(date);
  }
  return result;
}

/// Kemunculan pertama [rule] pada atau sesudah [date], atau `null` bila
/// rutinnya sudah berakhir.
DateTime? nextOccurrence(RecurringRule rule, DateTime date) {
  final start = DateTime(date.year, date.month, date.day);
  for (var n = 0; ; n++) {
    final occurrence = _occurrenceWithinEnd(rule, n);
    if (occurrence == null) return null;
    if (!occurrence.isBefore(start)) return occurrence;
  }
}

/// Kemunculan terakhir [rule], atau `null` bila rutinnya tidak pernah
/// berakhir.
DateTime? lastOccurrence(RecurringRule rule) {
  switch (rule.end) {
    case RecurringNeverEnds():
      return null;
    case RecurringEndsAfter(:final count):
      return rule.schedule.occurrenceAt(count - 1);
    case RecurringEndsOn():
      DateTime? last;
      for (var n = 0; ; n++) {
        final occurrence = _occurrenceWithinEnd(rule, n);
        if (occurrence == null) return last;
        last = occurrence;
      }
  }
}

/// Kemunculan ke-[n], atau `null` bila sudah melewati akhir rutin.
DateTime? _occurrenceWithinEnd(RecurringRule rule, int n) {
  final date = rule.schedule.occurrenceAt(n);
  return switch (rule.end) {
    RecurringNeverEnds() => date,
    RecurringEndsAfter(:final count) => n < count ? date : null,
    RecurringEndsOn(date: final endDate) =>
      date.isAfter(DateTime(endDate.year, endDate.month, endDate.day)) ? null : date,
  };
}
