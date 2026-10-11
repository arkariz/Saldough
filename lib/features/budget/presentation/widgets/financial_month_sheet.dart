import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';

/// Anggaran rutin yang bisa ikut pindah ke awal bulan keuangan baru.
typedef FinancialMonthBudgetOption = ({String templateId, String name});

/// Akibat memilih tanggal mulai baru (FINANCIAL_PERIOD F3): periode
/// sebelumnya yang tidak berubah, periode berjalan sesudah diubah (peralihan
/// bila panjangnya berubah), dan periode berikutnya.
typedef FinancialMonthPreview = ({FinancialPeriod previous, FinancialPeriod current, FinancialPeriod next});

/// [FinancialMonthPreview] bila tanggal mulai [schedule] diubah ke [start]
/// pada [today] (P-3).
FinancialMonthPreview financialMonthPreview(
  FinancialMonthSchedule schedule,
  DateTime today,
  FinancialMonthStart start,
) {
  final after = schedule.changedOn(today, start);
  final current = after.periodOf(schedule.periodOf(today).start);
  return (previous: after.previousOf(current), current: current, next: after.nextOf(current));
}

/// Anggaran rutin bulanan yang aktif dan berpatokan sama dengan awal bulan
/// keuangan [active] (F3 langkah 2). Yang berpatokan lain (mis. 15) tidak
/// ditawarkan dan tidak berubah (P-6).
List<FinancialMonthBudgetOption> movableRecurringBudgets(
  Iterable<BudgetTemplate> templates,
  FinancialMonthStart active,
) => [
  for (final template in templates)
    if (template.schedule case final schedule?
        when schedule.isActive &&
            schedule.period == BudgetPeriod.monthly &&
            schedule.onLastDay == active.isLastDay &&
            (schedule.onLastDay || schedule.anchorDate.day == active.day))
      (templateId: template.id, name: template.name),
];

/// Lembar Awal bulan keuangan (komponen DayPicker, FINANCIAL_PERIOD F1, F3):
/// kisi tanggal, pratinjau periode peralihan dengan garis waktunya, lalu
/// anggaran rutin yang ikut pindah. Dibuka dari kepala Rencana › Bulan ini
/// dan dari Akun. [onSave] menerima tanggal terpilih dan template anggaran
/// yang dicentang, dan mengembalikan `true` bila tersimpan; Batal tidak
/// mengubah apa pun.
class FinancialMonthSheet extends StatefulWidget {
  /// Membuat [FinancialMonthSheet].
  const FinancialMonthSheet({
    required this.schedule,
    required this.today,
    required this.budgets,
    required this.onSave,
    this.initial,
    super.key,
  });

  /// Tanggal yang sudah terpilih saat dibuka (tawaran rutin gajian, F2);
  /// `null` = tanggal aktif.
  final FinancialMonthStart? initial;

  /// Jadwal aktif.
  final FinancialMonthSchedule schedule;

  /// Hari ini.
  final DateTime today;

  /// Anggaran rutin yang patokannya sama dengan awal bulan aktif.
  final List<FinancialMonthBudgetOption> budgets;

  /// Menyimpan pilihan.
  final Future<bool> Function(FinancialMonthStart start, Set<String> movedTemplateIds) onSave;

  @override
  State<FinancialMonthSheet> createState() => _FinancialMonthSheetState();
}

class _FinancialMonthSheetState extends State<FinancialMonthSheet> {
  late FinancialMonthStart _pick = widget.initial ?? widget.schedule.active;
  final _off = <String>{};
  bool _saving = false;

  bool get _changed => _pick != widget.schedule.active;

  static String _on(FinancialMonthStart start) => switch (start.day) {
    final day? => t.plan.financialMonthOnDay(day: day),
    null => t.plan.financialMonthOnLastDay,
  };

  Future<void> _save() async {
    setState(() => _saving = true);
    final moved = {
      for (final b in widget.budgets)
        if (!_off.contains(b.templateId)) b.templateId,
    };
    final saved = await widget.onSave(_pick, moved);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: colors.ink2);
    const gutter = EdgeInsets.symmetric(horizontal: AppSpacing.space4);
    final preview = _changed ? financialMonthPreview(widget.schedule, widget.today, _pick) : null;
    final allOn = _off.isEmpty;
    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.space1, AppSpacing.space1, AppSpacing.space1, 0),
            child: AppFormHeader(title: t.plan.financialMonthTitle),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(padding: gutter, child: Text(t.plan.financialMonthHint, style: muted)),
                  const SizedBox(height: AppSpacing.space3),
                  Padding(
                    padding: gutter,
                    child: AppDayGrid(selected: _pick, onSelected: (start) => setState(() => _pick = start)),
                  ),
                  if (preview != null) ...[
                    const SizedBox(height: AppSpacing.space3),
                    Padding(padding: gutter, child: _Preview(preview: preview, start: _pick)),
                    if (widget.budgets.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space4),
                      Padding(
                        padding: gutter,
                        child: Row(
                          children: [
                            Expanded(child: Text(t.plan.financialMonthBudgetsTitle, style: textTheme.titleMedium)),
                            if (widget.budgets.length >= 2)
                              AppButton.text(
                                key: const ValueKey('financial-month-bulk'),
                                label: allOn ? t.plan.financialMonthClearAll : t.plan.financialMonthSelectAll,
                                onPressed: () => setState(() {
                                  if (allOn) {
                                    _off.addAll(widget.budgets.map((b) => b.templateId));
                                  } else {
                                    _off.clear();
                                  }
                                }),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: gutter,
                        child: Text(
                          t.plan.financialMonthBudgetsHelp(next: _on(_pick), previous: _on(widget.schedule.active)),
                          style: muted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      for (final budget in widget.budgets)
                        AppCheckRow(
                          key: ValueKey('financial-month-budget-${budget.templateId}'),
                          title: budget.name,
                          value: !_off.contains(budget.templateId),
                          subtitle: _off.contains(budget.templateId)
                              ? t.plan.financialMonthBudgetKept(start: _on(widget.schedule.active))
                              : t.plan.financialMonthBudgetMoved(
                                  until: CycleMonthFormatter.formatDayMonth(preview.current.lastDay),
                                  next: CycleMonthFormatter.formatDayMonth(preview.current.end),
                                ),
                          onChanged: (on) => setState(() {
                            if (on) {
                              _off.remove(budget.templateId);
                            } else {
                              _off.add(budget.templateId);
                            }
                          }),
                        ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          AppStickyBar(
            child: Row(
              children: [
                AppButton.text(label: t.common.cancel, onPressed: () => Navigator.of(context).pop(false)),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: AppButton(
                    key: const ValueKey('financial-month-save'),
                    label: t.common.save,
                    expand: true,
                    loading: _saving,
                    onPressed: _changed && !_saving ? () => unawaited(_save()) : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pratinjau (`tk-inset`): judul, kalimat periode peralihan, garis waktu,
/// lalu "Periode sebelumnya tidak berubah."
class _Preview extends StatelessWidget {
  const _Preview({required this.preview, required this.start});

  final FinancialMonthPreview preview;
  final FinancialMonthStart start;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final current = preview.current;
    return ColoredBox(
      key: const ValueKey('financial-month-preview'),
      color: colors.surface2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              switch (start.day) {
                final day? => t.plan.financialMonthPreviewTitle(day: day),
                null => t.plan.financialMonthPreviewTitleLastDay,
              },
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              t.plan.financialMonthPreviewTransition(
                range: current.rangeLabel,
                days: current.days,
                next: preview.next.rangeLabel,
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.space2),
            AppPeriodTimeline(
              previousDays: preview.previous.days,
              currentDays: current.days,
              nextDays: preview.next.days,
              startLabel: CycleMonthFormatter.formatDayMonth(current.start),
              endLabel: CycleMonthFormatter.formatDayMonth(current.end),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(t.plan.financialMonthPreviewPast, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
          ],
        ),
      ),
    );
  }
}
