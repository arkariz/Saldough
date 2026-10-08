import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/features/budget/presentation/budget_display.dart';

/// Kartu utama layar Anggaran ([AppSummaryCard], FR-BUD-004, rujukan
/// `pixel_kas_daftar_anggaran`): SISA lintas seluruh anggaran AKTIF sebagai
/// angka utama, lalu bilah progres gabungan, rencana dan terpakai, dan
/// pengingat bahwa anggaran bukan pemotongan saldo.
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
    return AppSummaryCard(
      tour: TourId.budget,
      icon: IconKey.budget,
      label: t.budget.remainingLabel,
      trailing: BudgetBadge(
        label: t.budget.activeBadge(count: activeCount),
        color: colors.positive,
        background: colors.tinted(colors.positive, 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroAmount(AppMoneyFormatter.format(remaining), color: remaining < 0 ? colors.danger : null),
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space2,
            runSpacing: 4,
            children: [
              Text(t.budget.summaryTitle.toUpperCase(), style: labelSmStyle(context, color: colors.ink2)),
              Text(
                t.budget.summaryPercent(percent: budgetPercent(spent, planned)).toUpperCase(),
                style: labelSmStyle(context, color: AppProgressBar.colorFor(context, ratio)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          BudgetProgressBar(value: ratio, height: 14),
          const SizedBox(height: AppSpacing.space2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stat(label: t.budget.plannedLabel, sen: planned, color: colors.ink),
              ),
              Expanded(
                child: _Stat(label: t.budget.spentLabel, sen: spent, color: colors.ink, alignEnd: true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          HeroInset(child: Text(t.budget.summaryNote, style: textTheme.bodySmall)),
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
        Text(label.toUpperCase(), style: labelSmStyle(context, color: context.appColors.ink2)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: Text(AppMoneyFormatter.format(sen), style: context.numberStyles.amountSm.copyWith(color: color)),
        ),
      ],
    );
  }
}
