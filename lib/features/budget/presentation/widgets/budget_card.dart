import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_status.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/features/budget/presentation/budget_display.dart';

/// Satu kartu di layar Anggaran (T-4.5, rujukan `pixel_kas_daftar_anggaran`).
///
/// ⚠ Delapan isian wajib: nama, dompet, periode, nominal rencana, terpakai,
/// sisa, progres, dan status. Nama dompet selalu terbaca tanpa membuka
/// anggarannya. Lewat anggaran diwarnai `overBudget` — keadaan nyata, bukan
/// kesalahan (FR-BUD-004).
class BudgetCard extends StatelessWidget {
  /// Membuat [BudgetCard].
  const BudgetCard({
    required this.budget,
    required this.progress,
    required this.walletName,
    required this.onTap,
    super.key,
  });

  /// Anggaran yang ditampilkan.
  final Budget budget;

  /// Progres anggaran itu.
  final BudgetProgress progress;

  /// Nama dompet anggaran (atau label "tidak ditemukan").
  final String walletName;

  /// Dipanggil saat kartu diketuk.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final overspent = progress.spendingStatus == BudgetItemStatus.overspent;
    final dimmed = progress.status != BudgetStatus.active;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: dimmed ? 0.7 : 1,
          child: TransactionSlab(
            color: overspent ? colors.tinted(colors.expenseFill, 0.08) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(budget.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const AppIcon(IconKey.chevronRight),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    BudgetBadge(label: walletName, color: colors.textPrimary),
                    BudgetBadge(label: '${budgetPeriodLabel(budget.period)} · ${budgetRangeLabel(budget)}'),
                    BudgetBadge(
                      label: budgetStatusLabel(progress.status),
                      color: progress.status == BudgetStatus.active ? colors.income : colors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                BudgetProgressBar(value: progress.progress),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.budget
                                .spentPercentLabel(percent: budgetPercent(progress.spent, progress.plannedAmount))
                                .toUpperCase(),
                            style: transactionLabelStyle(context, color: colors.textMuted),
                          ),
                          FitStart(
                            child: Text(
                              AppMoneyFormatter.format(progress.spent),
                              style: PixelTypography.tabularMono(
                                context,
                                fontSize: 16,
                                color: overspent ? colors.overBudget : colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${t.budget.remainingLabel} / ${t.budget.plannedLabel}'.toUpperCase(),
                            textAlign: TextAlign.end,
                            style: transactionLabelStyle(context, color: colors.textMuted),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: AppMoneyFormatter.format(progress.remaining),
                                    style: TextStyle(color: progress.remaining < 0 ? colors.overBudget : colors.income),
                                  ),
                                  TextSpan(text: ' / ${AppMoneyFormatter.format(progress.plannedAmount)}'),
                                ],
                              ),
                              style: PixelTypography.tabularMono(context, color: colors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (overspent) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    budgetItemStatusLabel(BudgetItemStatus.overspent).toUpperCase(),
                    style: transactionLabelStyle(context, color: colors.overBudget),
                  ),
                ],
                if (budget.items.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    t.budget.itemCount(count: budget.items.length),
                    style: transactionLabelStyle(
                      context,
                      color: colors.textMuted,
                    ).copyWith(fontWeight: FontWeight.w400),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
