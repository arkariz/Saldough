import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';

/// Kartu utama segmen Anggaran (FR-BUD-004): sisa lintas seluruh anggaran
/// AKTIF sebagai angka utama, bilah terpakai, lalu rencana dan terpakai.
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
    final remaining = planned - spent;
    return DsSummaryHero(
      label: t.budget.remainingLabel,
      badge: t.budget.activeBadge(count: activeCount),
      amount: remaining,
      negative: remaining < 0,
      format: AppMoneyFormatter.format,
      ratio: planned <= 0 ? 0 : spent / planned,
      asset: ClayIcons.piggy,
      semanticLabel: '${t.budget.remainingLabel} ${AppMoneyFormatter.format(remaining)}',
      stats: [
        DsSummaryStat(label: t.budget.plannedLabel, value: AppMoneyFormatter.format(planned)),
        DsSummaryStat(label: t.budget.spentLabel, value: AppMoneyFormatter.format(spent)),
      ],
    );
  }
}
