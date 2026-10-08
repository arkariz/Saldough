import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';

/// Kartu utama segmen Anggaran (prototipe `RencanaAnggaran.dc.html`,
/// FR-BUD-004): sisa lintas seluruh anggaran AKTIF sebagai angka utama, lalu
/// rencana dan terpakai di bidang cekung `surface2`.
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
    Widget row(String label, Widget amount) => Row(
      children: [
        Expanded(child: Text(label, style: textTheme.bodyMedium?.copyWith(color: colors.ink2))),
        Flexible(child: FitStart(child: amount)),
      ],
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.budget.remainingLabel, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
          HeroAmount(AppMoneyFormatter.format(remaining), color: remaining < 0 ? colors.danger : null),
          const SizedBox(height: AppSpacing.space3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            color: colors.surface2,
            child: Column(
              children: [
                row(t.budget.plannedLabel, AppMoneyText(planned, size: MoneySize.small)),
                const SizedBox(height: AppSpacing.space2),
                row(t.budget.spentLabel, AppMoneyText(spent, kind: MoneyKind.expense, size: MoneySize.small)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
