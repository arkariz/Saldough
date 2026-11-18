import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';

/// Bagian "Perkiraan tercapai" di rincian tujuan (ADR-048 §3.6, §3.7, Plus):
/// baris laju dompet tujuan, baris skenario uang nganggur, dan baris
/// "Perkiraan melewati target tanggal". Semua berlabel perkiraan.
class GoalEstimateSection extends StatelessWidget {
  /// Membuat [GoalEstimateSection].
  const GoalEstimateSection({required this.estimate, super.key});

  /// Hasil hitungan.
  final SavingsGoalEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final e = t.assets.goal.estimate;
    final rate = estimate.rate;
    final rateDate = estimate.rateDate;
    final idleDate = estimate.idleDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsSectionHeader(title: e.title),
        DsListCard(
          children: [
            DsSettingRow(
              key: const ValueKey('goal-estimate-rate'),
              leading: const DsIconTile(icon: Icons.trending_up_rounded),
              title: e.rateLabel,
              subtitle: rate != null
                  ? e.rateBody(amount: AppMoneyText.format(rate, MoneyKind.balance))
                  : switch (estimate.blocker) {
                      GoalEstimateBlocker.notSaving => e.notSaving,
                      _ => e.notEnoughHistory,
                    },
              trailing: _DateText(rateDate == null ? e.notYet : CycleMonthFormatter.formatMonthYearShort(rateDate)),
            ),
            if (idleDate != null)
              DsSettingRow(
                key: const ValueKey('goal-estimate-idle'),
                leading: const DsIconTile(icon: Icons.savings_outlined),
                title: e.idleLabel,
                subtitle: e.idleBody,
                trailing: _DateText(CycleMonthFormatter.formatMonthYearShort(idleDate)),
              ),
          ],
        ),
        if (estimate.beyondTarget) ...[
          const SizedBox(height: 8),
          Row(
            key: const ValueKey('goal-estimate-beyond'),
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: c.warning),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  e.beyondTarget,
                  style: ds.typography.bodySm.copyWith(color: c.warning, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(e.footnote, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
      ],
    );
  }
}

/// Bagian terkunci untuk Gratis: satu baris yang membuka paywall.
class GoalEstimateLocked extends StatelessWidget {
  /// Membuat [GoalEstimateLocked].
  const GoalEstimateLocked({required this.onTap, super.key});

  /// Membuka paywall perkiraan tujuan.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = t.assets.goal.estimate;
    return DsListCard(
      children: [
        DsSettingRow(
          key: const ValueKey('goal-estimate-locked'),
          leading: const DsIconTile(icon: Icons.trending_up_rounded),
          title: e.lockedTitle,
          subtitle: e.lockedBody,
          badge: DsBadge(label: t.premium.plusBadge, tone: DsBadgeTone.income),
          onTap: onTap,
        ),
      ],
    );
  }
}

class _DateText extends StatelessWidget {
  const _DateText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Text(text, style: ds.typography.titleMd.copyWith(fontSize: 14, fontWeight: FontWeight.w800));
  }
}
