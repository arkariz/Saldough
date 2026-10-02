import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Kartu utama segmen Rutin (PLAN_TAB_LAYOUT §4.9): "Sisa rutin keluar"
/// = Rencana − Sudah keluar, dan total langganan (W5) bila ada. Pemasukan
/// terjadwal ada di Bulan ini, tidak diulang di sini.
class RecurringSummaryCard extends StatelessWidget {
  /// Membuat [RecurringSummaryCard].
  const RecurringSummaryCard({required this.summary, required this.monthLabel, this.subscriptions, super.key});

  /// Ringkasan bulan berjalan.
  final RecurringMonthSummary summary;

  /// Label bulan ("Okt").
  final String monthLabel;

  /// W5, bila ada dua langganan atau lebih.
  final ({int perMonth, int perYear})? subscriptions;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final remaining = AppMoneyFormatter.format(summary.remainingOut);
    Widget row(String label, int sen, {bool minus = false}) => Row(
      children: [
        Expanded(child: Text(label, style: textTheme.bodyMedium)),
        Text(
          '${minus ? '−' : ''}${AppMoneyFormatter.format(sen)}',
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
    return AppHeroCard(
      icon: IconKey.budget,
      label: t.recurring.remainingTitle(month: monthLabel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: summary.hasEstimate ? t.recurring.approxSemantics(amount: remaining) : remaining,
            excludeSemantics: true,
            child: HeroAmount(summary.hasEstimate ? '≈$remaining' : remaining),
          ),
          const SizedBox(height: AppSpacing.sm),
          row(t.recurring.plannedLabel, summary.totalOut),
          row(t.recurring.outLabel, summary.recordedOut, minus: true),
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
