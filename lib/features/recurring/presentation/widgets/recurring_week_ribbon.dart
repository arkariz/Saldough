import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Satu rutin yang jatuh tempo dalam tujuh hari ke depan.
typedef WeekDue = ({DateTime date, RecurringRule rule});

/// Rutin aktif yang jatuh tempo dari [today] sampai enam hari sesudahnya,
/// urut tanggal. Murni jadwal: tidak membaca transaksi.
List<WeekDue> weekDues(Iterable<RecurringRule> rules, DateTime today) {
  final from = DateTime(today.year, today.month, today.day);
  final until = DateTime(today.year, today.month, today.day + 7);
  return [
    for (final rule in rules)
      if (!rule.isPaused)
        for (final date in occurrencesOf(rule, from: from, until: until))
          if (!rule.skippedDates.contains(date)) (date: date, rule: rule),
  ]..sort((a, b) => a.date.compareTo(b.date));
}

/// Pita **7 hari ke depan** (acuan Rutin): kepala dengan ikon kalender clay
/// dan rentang bulan, lalu tujuh hari yang bergulir mendatar. Hari yang ada
/// jatuh temponya melebar, memuat nama rutin, dan bertitik berdenyut; hari
/// ini diberi garis aksi.
class RecurringWeekRibbon extends StatelessWidget {
  /// Membuat [RecurringWeekRibbon].
  const RecurringWeekRibbon({required this.today, required this.dues, super.key});

  /// Hari ini.
  final DateTime today;

  /// Jatuh tempo tujuh hari ke depan, dari [weekDues].
  final List<WeekDue> dues;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final first = DateTime(today.year, today.month, today.day);
    final last = DateTime(today.year, today.month, today.day + 6);
    final range = first.month == last.month
        ? CycleMonthFormatter.formatMonthShort(first)
        : '${CycleMonthFormatter.formatMonthShort(first)} – ${CycleMonthFormatter.formatMonthShort(last)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              DsIconTile.asset(asset: ClayIcons.dateCalendar, size: DsIconTileSize.xs),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(t.recurring.ribbonTitle, style: ds.typography.titleMd.copyWith(fontSize: 15)),
                ),
              ),
              Text(range, style: ds.typography.labelMd.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Tujuh hari sebaris selebar layar: tanpa gulir, tanpa nama rutin
        // (nama ada di umpan di bawah dan di pembaca layar).
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: DsReveal(
                  index: i,
                  child: _Day(
                    date: DateTime(today.year, today.month, today.day + i),
                    isToday: i == 0,
                    due: dues.where((d) => d.date == DateTime(today.year, today.month, today.day + i)).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.date, required this.isToday, required this.due});

  final DateTime date;
  final bool isToday;
  final List<WeekDue> due;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final has = due.isNotEmpty;
    final weekday = CycleMonthFormatter.formatWeekday(date).substring(0, 3);
    Widget dot({required bool on}) => Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(shape: BoxShape.circle, color: on ? c.actionPrimary : c.outlineSubtle),
    );
    return Semantics(
      label: ['$weekday ${date.day}', for (final d in due) d.rule.note].join(', '),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: has ? c.actionPrimary.withValues(alpha: 0.10) : c.surfaceCard,
          borderRadius: DsRadius.mdAll,
          border: Border.all(
            color: isToday ? c.actionPrimary : (has ? c.actionPrimary.withValues(alpha: 0.25) : c.outlineSubtle),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                weekday,
                style: ds.typography.labelMd.copyWith(fontSize: 11, color: has ? c.actionPrimary : c.textSecondary),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${date.day}',
                style: ds.typography.titleMd.copyWith(color: has ? c.actionPrimary : c.textPrimary),
              ),
            ),
            const SizedBox(height: 4),
            // Satu titik per jatuh tempo (maksimal tiga).
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 3,
              children: [
                if (!has)
                  dot(on: false)
                else
                  for (var i = 0; i < due.length.clamp(1, 3); i++)
                    if (i == 0) DsPulse(borderRadius: DsRadius.fullAll, child: dot(on: true)) else dot(on: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
