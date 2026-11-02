import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';

/// Kartu utama segmen Anggaran (FR-BUD-004): sisa lintas seluruh anggaran
/// AKTIF sebagai angka utama, lalu rencana dan terpakai di bidang cekung.
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
    final ds = context.ds;
    final c = ds.colors;
    final remaining = planned - spent;
    Widget row(String label, String asset, String amount, {Color? color}) => Row(
      children: [
        DsIconTile.asset(asset: asset, size: DsIconTileSize.sm),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: ds.typography.bodyMd.copyWith(color: c.textSecondary)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(amount, style: ds.typography.amount.copyWith(color: color)),
          ),
        ),
      ],
    );
    return DsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.budget.remainingLabel.toUpperCase(),
            style: ds.typography.pixelCaption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              AppMoneyFormatter.format(remaining),
              style: ds.typography.numericalDisplay.copyWith(color: remaining < 0 ? c.error : c.textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.mdAll),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  row(t.budget.plannedLabel, ClayIcons.piggy, AppMoneyFormatter.format(planned)),
                  const SizedBox(height: 10),
                  row(t.budget.spentLabel, ClayIcons.expenseArrow, AppMoneyFormatter.format(spent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
