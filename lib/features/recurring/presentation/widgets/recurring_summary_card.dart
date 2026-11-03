import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
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
    final ds = context.ds;
    final remaining = AppMoneyFormatter.format(summary.remainingOut);
    String show(int sen) => summary.hasEstimate ? '≈${AppMoneyFormatter.format(sen)}' : AppMoneyFormatter.format(sen);
    return DsSummaryHero(
      label: t.recurring.remainingTitle(month: monthLabel),
      amount: summary.remainingOut,
      format: show,
      ratio: summary.totalOut <= 0 ? 0 : summary.recordedOut / summary.totalOut,
      asset: ClayIcons.calendar,
      semanticLabel: summary.hasEstimate ? t.recurring.approxSemantics(amount: remaining) : remaining,
      stats: [
        DsSummaryStat(label: t.recurring.plannedLabel, value: AppMoneyFormatter.format(summary.totalOut)),
        DsSummaryStat(label: t.recurring.outLabel, value: AppMoneyFormatter.format(summary.recordedOut)),
      ],
      footer: subscriptions == null
          ? null
          : Row(
              children: [
                Icon(Icons.subscriptions_outlined, size: 16, color: ds.colors.onHeroMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.recurring.subscriptionsLine(
                      perMonth: AppMoneyFormatter.format(subscriptions!.perMonth),
                      perYear: AppMoneyFormatter.format(subscriptions!.perYear),
                    ),
                    style: ds.typography.bodySm.copyWith(color: ds.colors.onHeroMuted),
                  ),
                ),
              ],
            ),
    );
  }
}
