import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Kartu utama segmen Rutin (PLAN_TAB_LAYOUT §6.1): "Masih akan keluar"
/// sebagai angka utama, bilah tercatat dari total, masuk terjadwal, dan
/// total langganan (W5) bila ada. Angka saja; penjelasan di dokumen, bukan
/// di kartu (§4.9).
class RecurringSummaryCard extends StatelessWidget {
  /// Membuat [RecurringSummaryCard].
  const RecurringSummaryCard({required this.summary, required this.month, this.subscriptions, super.key});

  /// Ringkasan bulan berjalan.
  final RecurringMonthSummary summary;

  /// Bulan yang diringkas.
  final DateTime month;

  /// W5, bila ada dua langganan atau lebih.
  final ({int perMonth, int perYear})? subscriptions;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final remaining = AppMoneyFormatter.format(summary.remainingOut);
    final ratio = summary.totalOut == 0 ? 0.0 : summary.recordedOut / summary.totalOut;
    return AppHeroCard(
      icon: IconKey.budget,
      label: t.recurring.summaryTitle(month: CycleMonthFormatter.formatMonthShort(month)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.recurring.remainingOutLabel, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
          Semantics(
            label: summary.hasEstimate ? t.recurring.approxSemantics(amount: remaining) : remaining,
            excludeSemantics: true,
            child: HeroAmount(summary.hasEstimate ? '≈$remaining' : remaining),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSegmentedProgressBar(value: ratio),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.recurring.recordedOfTotal(
              recorded: AppMoneyFormatter.format(summary.recordedOut),
              total: AppMoneyFormatter.format(summary.totalOut),
            ),
            style: textTheme.bodySmall,
          ),
          if (summary.scheduledIn > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: Text(t.recurring.scheduledInLabel, style: textTheme.bodyMedium)),
                Text(
                  AppMoneyFormatter.format(summary.scheduledIn),
                  style: textTheme.bodyMedium?.copyWith(color: colors.income, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
          if (subscriptions case final totals?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.recurring.subscriptionsLine(
                perMonth: AppMoneyFormatter.format(totals.perMonth),
                perYear: AppMoneyFormatter.format(totals.perYear),
              ),
              style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
