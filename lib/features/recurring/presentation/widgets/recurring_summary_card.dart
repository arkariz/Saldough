import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/recurring/presentation/recurring_display.dart';
import 'package:saldough/features/recurring/presentation/widgets/recurring_week_ribbon.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Kartu utama segmen Rutin (PLAN_TAB_LAYOUT §4.9): "Sisa rutin keluar"
/// = Rencana − Sudah keluar, dan total langganan (W5) bila ada. Pemasukan
/// terjadwal ada di Bulan ini, tidak diulang di sini.
class RecurringSummaryCard extends StatelessWidget {
  /// Membuat [RecurringSummaryCard].
  const RecurringSummaryCard({
    required this.summary,
    required this.monthLabel,
    this.subscriptions,
    this.nearest,
    this.today,
    this.idleCount = 0,
    this.idleTotal = 0,
    super.key,
  });

  /// Ringkasan bulan berjalan.
  final RecurringMonthSummary summary;

  /// Label bulan ("Okt").
  final String monthLabel;

  /// W5, bila ada dua langganan atau lebih.
  final ({int perMonth, int perYear})? subscriptions;

  /// Jatuh tempo terdekat dalam tujuh hari, atau `null`.
  final WeekDue? nearest;

  /// Hari ini, untuk teks jatuh tempo terdekat.
  final DateTime? today;

  /// Jumlah rutin menganggur (W6, hanya Plus).
  final int idleCount;

  /// Total nominal rutin menganggur per bulan, sen.
  final int idleTotal;

  @override
  Widget build(BuildContext context) {
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
      footer: _footer(context),
    );
  }

  Widget? _footer(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final near = nearest;
    final cards = <Widget>[
      if (near != null && today != null)
        Expanded(
          child: DsSummaryGlass(
            child: _Highlight(
              icon: Icons.notifications_active_outlined,
              label: '${t.recurring.nearestLabel}: ${dueText(near.date, today!)}',
              title: near.rule.note.isEmpty ? t.record.repeat.fallbackName : near.rule.note,
              detail: signedAmount(near.rule.kind, near.rule.amount),
            ),
          ),
        ),
      if (idleCount > 0)
        Expanded(
          child: DsSummaryGlass(
            child: _Highlight(
              icon: Icons.savings_outlined,
              label: t.recurring.saveChanceLabel,
              title: '${AppMoneyFormatter.format(idleTotal)}${t.recurring.perMonthShort}',
              detail: t.recurring.idleServices(n: idleCount),
            ),
          ),
        ),
    ];
    final subs = subscriptions;
    if (cards.isEmpty && subs == null) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (subs != null)
          Row(
            children: [
              Icon(Icons.subscriptions_outlined, size: 16, color: c.onHeroMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.recurring.subscriptionsLine(
                    perMonth: AppMoneyFormatter.format(subs.perMonth),
                    perYear: AppMoneyFormatter.format(subs.perYear),
                  ),
                  style: ds.typography.bodySm.copyWith(color: c.onHeroMuted),
                ),
              ),
            ],
          ),
        if (subs != null && cards.isNotEmpty) const SizedBox(height: 12),
        if (cards.isNotEmpty) Row(spacing: 10, children: cards),
      ],
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.icon, required this.label, required this.title, required this.detail});

  final IconData icon;
  final String label;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: c.primaryFixed),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ds.typography.labelMd.copyWith(fontSize: 11, color: c.primaryFixed),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ds.typography.titleMd.copyWith(fontSize: 15, color: c.onHero),
        ),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ds.typography.bodySm.copyWith(fontSize: 12, color: c.onHeroMuted),
        ),
      ],
    );
  }
}
