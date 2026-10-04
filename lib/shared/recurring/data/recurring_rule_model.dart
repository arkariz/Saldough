import 'package:saldough/shared/recurring/domain/recurring_rule.dart';

/// Model serialisasi [RecurringRule] untuk dokumen `recurring` / `all`.
///
/// Tanggal ditulis `yyyy-MM-dd` (tanpa jam) karena kemunculan adalah hari,
/// bukan saat. Enum ditulis dengan `name`-nya.
abstract final class RecurringRuleModel {
  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  static const schemaVersion = 1;

  /// Membaca [RecurringRule] dari JSON.
  static RecurringRule fromJson(Map<String, dynamic> json) {
    final schedule = json['schedule'] as Map<String, dynamic>;
    final end = json['end'] as Map<String, dynamic>;
    final paymentMode = json['paymentMode'] as String?;
    return RecurringRule(
      id: json['id'] as String,
      kind: RecurringKind.values.byName(json['kind'] as String),
      amount: json['amount'] as int,
      amountMode: RecurringAmountMode.values.byName(json['amountMode'] as String),
      walletId: json['walletId'] as String,
      toWalletId: json['toWalletId'] as String?,
      categoryId: json['categoryId'] as String?,
      note: json['note'] as String,
      schedule: RecurringSchedule(
        frequency: RecurringFrequency.values.byName(schedule['frequency'] as String),
        interval: schedule['interval'] as int,
        anchorDate: DateTime.parse(schedule['anchorDate'] as String),
        anchorDay: schedule['anchorDay'] as int,
      ),
      end: switch (end['type'] as String) {
        'untilDate' => RecurringEndsOn(DateTime.parse(end['date'] as String)),
        'count' => RecurringEndsAfter(end['count'] as int),
        _ => const RecurringNeverEnds(),
      },
      paymentMode: paymentMode == null ? null : RecurringPaymentMode.values.byName(paymentMode),
      remindDaysBefore: json['remindDaysBefore'] as int,
      // Ditambahkan T-15.8; dokumen sebelumnya tanpa kunci ini = nyala.
      reminders: json['reminders'] as bool? ?? true,
      autoRecord: json['autoRecord'] as bool,
      skippedDates: {for (final d in json['skippedDates'] as List<dynamic>) DateTime.parse(d as String)},
      isPaused: json['isPaused'] as bool,
      budgetItemKey: json['budgetItemKey'] as String?,
    );
  }

  /// Menulis [rule] ke JSON.
  static Map<String, dynamic> toJson(RecurringRule rule) => {
    'id': rule.id,
    'kind': rule.kind.name,
    'amount': rule.amount,
    'amountMode': rule.amountMode.name,
    'walletId': rule.walletId,
    'toWalletId': rule.toWalletId,
    'categoryId': rule.categoryId,
    'note': rule.note,
    'schedule': {
      'frequency': rule.schedule.frequency.name,
      'interval': rule.schedule.interval,
      'anchorDate': _day(rule.schedule.anchorDate),
      'anchorDay': rule.schedule.anchorDay,
    },
    'end': switch (rule.end) {
      RecurringNeverEnds() => {'type': 'none'},
      RecurringEndsOn(:final date) => {'type': 'untilDate', 'date': _day(date)},
      RecurringEndsAfter(:final count) => {'type': 'count', 'count': count},
    },
    'paymentMode': rule.paymentMode?.name,
    'remindDaysBefore': rule.remindDaysBefore,
    'reminders': rule.reminders,
    'autoRecord': rule.autoRecord,
    'skippedDates': (rule.skippedDates.toList()..sort()).map(_day).toList(),
    'isPaused': rule.isPaused,
    'budgetItemKey': rule.budgetItemKey,
  };

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
