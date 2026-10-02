import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Jenis tampilan [kind] (warna dan ikon jenis).
TransactionKind transactionKindOf(RecurringKind kind) => switch (kind) {
  RecurringKind.income => TransactionKind.income,
  RecurringKind.expense => TransactionKind.expense,
  RecurringKind.transfer => TransactionKind.transfer,
};

/// Nominal bertanda jenis (`+`, `−`, `⇄`), berawalan `≈` bila kira-kira
/// (PLAN_TAB_LAYOUT §6.3).
String signedAmount(RecurringKind kind, int sen, {bool approximate = false}) {
  final sign = switch (kind) {
    RecurringKind.income => '+',
    RecurringKind.expense => '−',
    RecurringKind.transfer => '⇄',
  };
  return '${approximate ? '≈' : ''}$sign${AppMoneyFormatter.format(sen)}';
}

/// Kalimat jadwal [rule]: "Tiap tanggal 10", "Tiap Kamis", "Tiap 12 Mar",
/// ditambah selang bila lebih dari satu.
String scheduleText(RecurringRule rule) {
  final schedule = rule.schedule;
  final base = switch (schedule.frequency) {
    RecurringFrequency.weekly => t.record.repeat.everyWeekday(
      day: CycleMonthFormatter.formatWeekday(schedule.anchorDate),
    ),
    RecurringFrequency.monthly => t.record.repeat.everyMonthDay(day: schedule.anchorDay),
    RecurringFrequency.yearly => t.record.repeat.everyYearDate(
      date: CycleMonthFormatter.formatDayMonth(schedule.anchorDate),
    ),
  };
  if (schedule.interval == 1) return base;
  final every = switch (schedule.frequency) {
    RecurringFrequency.weekly => t.record.repeat.everyNWeeks(n: schedule.interval),
    RecurringFrequency.monthly => t.record.repeat.everyNMonths(n: schedule.interval),
    RecurringFrequency.yearly => t.record.repeat.everyNYears(n: schedule.interval),
  };
  return '$base · $every';
}

/// Tanggal kemunculan ringkas: "1 Okt", ditambah tahun bila bukan tahun
/// [today].
String occurrenceDateText(DateTime date, DateTime today) =>
    date.year == today.year ? CycleMonthFormatter.formatDayMonth(date) : CycleMonthFormatter.formatDateShort(date);
