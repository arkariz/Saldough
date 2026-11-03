import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Distribusi rencana keluar (acuan "Distribusi Aliran Dana"): satu bilah
/// bertumpuk yang tumbuh dari kiri dan tiga baris (Tagihan rutin, Anggaran,
/// Di luar rencana) berdot warna dengan nominal dan persen. Hanya angka yang
/// sudah dihitung layar ini; tidak tampil bila tidak ada pengeluaran.
class PlanDistribution extends StatelessWidget {
  /// Membuat [PlanDistribution].
  const PlanDistribution({required this.plan, super.key});

  /// Rencana bulan ini.
  final MonthPlan plan;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final parts = [
      (t.plan.billsRow, plan.plannedRecurringOut, c.actionPrimary, ClayIcons.calendar),
      (t.plan.budgetRow, plan.budgetPlanned, c.warning, ClayIcons.piggy),
      (t.plan.offPlanRow, plan.unplannedOut, c.textMuted, ClayIcons.coffee),
    ];
    final total = parts.fold<int>(0, (sum, p) => sum + p.$2);
    if (total <= 0) return const SizedBox.shrink();
    final reduced = DsMotion.reduced(context);
    return DsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.plan.distTitle, style: ds.typography.titleMd),
          const SizedBox(height: 14),
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: DsRadius.fullAll,
              child: SizedBox(
                height: 12,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: reduced ? 1 : 0, end: 1),
                  duration: const Duration(milliseconds: 1000),
                  curve: DsMotion.easeOutExpo,
                  builder: (context, progress, _) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Row(
                        children: [
                          for (final (i, p) in parts.indexed)
                            if (p.$2 > 0) ...[
                              if (i > 0 && parts.take(i).any((q) => q.$2 > 0)) const SizedBox(width: 2),
                              Expanded(
                                flex: (p.$2 * 1000 / total).round().clamp(1, 1000),
                                child: ColoredBox(color: p.$3),
                              ),
                            ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final (i, p) in parts.indexed)
            if (p.$2 > 0)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                child: Row(
                  children: [
                    DsIconTile.asset(asset: p.$4, size: DsIconTileSize.sm),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: p.$3),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  p.$1,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${(p.$2 * 100 / total).round()}%',
                            style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text('−${AppMoneyFormatter.format(p.$2)}', style: ds.typography.amount),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
