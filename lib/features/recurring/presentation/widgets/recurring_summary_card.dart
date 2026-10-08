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
    Widget row(String label, Widget amount) => Row(
      children: [
        Expanded(child: Text(label, style: textTheme.bodyMedium?.copyWith(color: colors.ink2))),
        Flexible(
          child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerEnd, child: amount),
        ),
      ],
    );
    // Prototipe `RencanaRutin.dc.html`: angka utama di kartu, rencana dan
    // sudah keluar di bidang cekung `surface2`.
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.recurring.remainingTitle(month: monthLabel), style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
          Semantics(
            label: summary.hasEstimate ? t.recurring.approxSemantics(amount: remaining) : remaining,
            excludeSemantics: true,
            child: HeroAmount(summary.hasEstimate ? '≈$remaining' : remaining),
          ),
          const SizedBox(height: AppSpacing.space3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            color: colors.surface2,
            child: Column(
              children: [
                row(t.recurring.plannedLabel, AppMoneyText(summary.totalOut, size: MoneySize.small)),
                const SizedBox(height: AppSpacing.space2),
                row(t.recurring.outLabel, AppMoneyText(summary.recordedOut, kind: MoneyKind.expense, size: MoneySize.small)),
              ],
            ),
          ),
          if (subscriptions case final totals?) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              t.recurring.subscriptionsLine(
                perMonth: AppMoneyFormatter.format(totals.perMonth),
                perYear: AppMoneyFormatter.format(totals.perYear),
              ),
              style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
            ),
          ],
        ],
      ),
    );
  }
}
