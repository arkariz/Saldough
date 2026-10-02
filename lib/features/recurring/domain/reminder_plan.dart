import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Jenis pengingat rutin (ADR-034 §3.8, J3).
enum ReminderKind {
  /// H−n sebelum jatuh tempo, untuk rutin yang dibayar sendiri.
  dueSoon,

  /// Ringkasan pada hari jatuh tempo.
  dueToday,
}

/// Satu notifikasi terjadwal.
final class PlannedReminder extends Equatable {
  /// Membuat [PlannedReminder].
  const PlannedReminder({required this.id, required this.at, required this.kind, required this.items});

  /// Id notifikasi, stabil dari isinya supaya penyusunan ulang tidak
  /// menggandakan.
  final int id;

  /// Waktu tampil (jam lokal).
  final DateTime at;

  /// Jenisnya.
  final ReminderKind kind;

  /// Kemunculan yang diingatkan.
  final List<({RecurringRule rule, DateTime date})> items;

  /// Payload ketukan: `record|<ruleId>|<yyyy-mm-dd>` bila satu kemunculan,
  /// selain itu `open`.
  String get payload => items.length == 1 ? reminderPayload(items.single.rule.id, items.single.date) : 'open';

  /// Aksi **Catat** hanya untuk satu kemunculan.
  bool get canRecord => items.length == 1;

  @override
  List<Object?> get props => [
    id,
    at,
    kind,
    [for (final i in items) (i.rule.id, i.date)],
  ];
}

/// Rentang penjadwalan: kemunculan sampai 35 hari ke depan (ADR-034 §3.8).
const reminderWindowDays = 35;

/// Jam pengingat.
const reminderHour = 9;

/// Pengingat yang perlu terjadwal per [now] (J3):
///
/// - H−n (`remindDaysBefore`) untuk pengeluaran dan transfer yang dibayar
///   sendiri;
/// - satu ringkasan per hari jatuh tempo untuk semua rutin.
///
/// Rutin dijeda, rutin dengan pengingat mati, kemunculan yang sudah
/// tercatat atau dilewati, dan waktu yang sudah lewat tidak dijadwalkan.
/// [transactions] memuat bulan berjalan dan bulan depan.
List<PlannedReminder> planReminders(
  Iterable<RecurringRule> rules, {
  required DateTime now,
  required Iterable<Transaction> transactions,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final until = DateTime(today.year, today.month, today.day + reminderWindowDays + 1);
  final soon = <PlannedReminder>[];
  final byDay = <DateTime, List<({RecurringRule rule, DateTime date})>>{};
  for (final rule in rules) {
    if (rule.isPaused || !rule.reminders) continue;
    final occurrences = occurrenceStatusesOf(rule, from: today, until: until, today: today, transactions: transactions);
    for (final o in occurrences) {
      if (o.status == OccurrenceStatus.recorded || o.status == OccurrenceStatus.skipped) continue;
      (byDay[o.date] ??= []).add((rule: rule, date: o.date));
      final manual = rule.kind != RecurringKind.income && rule.effectivePaymentMode == RecurringPaymentMode.manual;
      if (manual && rule.remindDaysBefore > 0) {
        final day = DateTime(o.date.year, o.date.month, o.date.day - rule.remindDaysBefore, reminderHour);
        if (day.isAfter(now)) {
          soon.add(
            PlannedReminder(
              id: reminderId('soon|${reminderPayload(rule.id, o.date)}'),
              at: day,
              kind: ReminderKind.dueSoon,
              items: [(rule: rule, date: o.date)],
            ),
          );
        }
      }
    }
  }
  final today9 = [
    for (final MapEntry(key: date, value: items) in byDay.entries)
      if (DateTime(date.year, date.month, date.day, reminderHour).isAfter(now))
        PlannedReminder(
          id: reminderId('day|${date.year}-${date.month}-${date.day}'),
          at: DateTime(date.year, date.month, date.day, reminderHour),
          kind: ReminderKind.dueToday,
          items: items..sort((a, b) => a.rule.note.compareTo(b.rule.note)),
        ),
  ];
  return [...soon, ...today9]..sort((a, b) => a.at.compareTo(b.at));
}

/// Payload satu kemunculan.
String reminderPayload(String ruleId, DateTime date) =>
    'record|$ruleId|${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Membaca payload [reminderPayload]; `null` bila bukan satu kemunculan.
({String ruleId, DateTime date})? parseReminderPayload(String? payload) {
  final parts = payload?.split('|');
  if (parts == null || parts.length != 3 || parts.first != 'record') return null;
  final date = DateTime.tryParse(parts[2]);
  return date == null ? null : (ruleId: parts[1], date: date);
}

/// Id notifikasi 31-bit yang stabil untuk [key] (FNV-1a), sehingga jadwal
/// yang disusun ulang menimpa notifikasi yang sama, tidak menggandakan.
int reminderId(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}
