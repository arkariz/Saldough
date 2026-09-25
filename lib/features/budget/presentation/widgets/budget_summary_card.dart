import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/features/budget/presentation/budget_display.dart';

/// Ringkasan puncak layar Anggaran (FR-BUD-004, rujukan
/// `pixel_kas_daftar_anggaran`): total rencana, terpakai, dan sisa lintas
/// seluruh anggaran AKTIF, bilah progres gabungan, dan pengingat bahwa
/// anggaran bukan pemotongan saldo.
class BudgetSummaryCard extends StatelessWidget {
  /// Membuat [BudgetSummaryCard].
  const BudgetSummaryCard({required this.planned, required this.spent, required this.activeCount, super.key});

  /// Total rencana anggaran aktif, sen.
  final int planned;

  /// Total terpakai anggaran aktif, sen.
  final int spent;

  /// Jumlah anggaran aktif.
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final remaining = planned - spent;
    final ratio = progressRatio(spent: spent, plannedAmount: planned);
    return TransactionSlab(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text(t.budget.heading, style: textTheme.titleLarge),
              BudgetBadge(
                label: t.budget.activeBadge(count: activeCount),
                color: colors.income,
                background: colors.tinted(colors.incomeFill, 0.2),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: 4,
            children: [
              Text(t.budget.summaryTitle.toUpperCase(), style: transactionLabelStyle(context, color: colors.textMuted)),
              Text(
                t.budget.summaryPercent(percent: budgetPercent(spent, planned)).toUpperCase(),
                style: transactionLabelStyle(context, color: AppSegmentedProgressBar.colorFor(context, ratio)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          BudgetProgressBar(value: ratio, height: 14),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stat(label: t.budget.plannedLabel, sen: planned, color: colors.textPrimary),
              ),
              Expanded(
                child: _Stat(label: t.budget.spentLabel, sen: spent, color: colors.expense),
              ),
              Expanded(
                child: _Stat(
                  label: t.budget.remainingLabel,
                  sen: remaining,
                  color: remaining < 0 ? colors.overBudget : colors.income,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: colors.surfaceHigh, borderRadius: BorderRadius.circular(8)),
            child: Text(t.budget.summaryNote, style: textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.sen, required this.color, this.alignEnd = false});

  final String label;
  final int sen;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: transactionLabelStyle(context, color: context.appColors.textMuted)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: Text(AppMoneyFormatter.format(sen), style: PixelTypography.tabularMono(context, color: color)),
        ),
      ],
    );
  }
}
