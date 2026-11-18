import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/shared/savings_goal/domain/savings_goal.dart';

/// Ikon tujuan dari `SavingsGoal.iconKey` (pilihan yang sama dengan kategori);
/// kunci yang tidak dikenal memakai celengan.
IconKey savingsGoalIconKey(String key) => IconKey.values.asNameMap()[key] ?? IconKey.walletSavings;

/// Ubin ikon clay tujuan.
Widget savingsGoalTile(String iconKey, {DsIconTileSize size = DsIconTileSize.md}) {
  final icon = savingsGoalIconKey(iconKey);
  final asset = ClayIcons.forIcon(icon);
  if (asset == null) return AppIconTile(icon);
  return DsIconTile.asset(asset: asset, size: size);
}

/// Kartu tujuan di tab Dompet (rupa B-96 §1): ikon, nama, "terkumpul dari
/// target", meter tipis, dan persen; Tercapai berlencana. Nominal ikut
/// Sembunyikan nominal.
class SavingsGoalCard extends StatelessWidget {
  /// Membuat [SavingsGoalCard].
  const SavingsGoalCard({required this.goal, required this.progress, this.onTap, super.key});

  /// Tujuan yang ditampilkan.
  final SavingsGoal goal;

  /// Kemajuannya, dihitung pemanggil dari saldo dompet.
  final SavingsGoalProgress progress;

  /// Membuka rincian.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final reached = goal.status == SavingsGoalStatus.completed;
    final archived = goal.status == SavingsGoalStatus.archived;
    return Opacity(
      opacity: archived ? 0.6 : 1,
      child: Semantics(
        button: onTap != null,
        label: goal.name,
        child: DsPressable(
          onPressed: onTap,
          builder: (context, _) => DsCard(
            child: Row(
              children: [
                savingsGoalTile(goal.iconKey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(goal.name, style: ds.typography.titleMd.copyWith(fontSize: 15))),
                          if (reached) DsBadge(label: t.assets.goal.reached, tone: DsBadgeTone.income),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.assets.goal.progress(
                          saved: AppMoneyText.format(progress.collected, MoneyKind.balance),
                          target: AppMoneyText.format(progress.target, MoneyKind.balance),
                        ),
                        style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DsSegmentMeter(
                              value: progress.percent / 100,
                              semanticLabel: '${progress.percent}%',
                              thin: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${progress.percent}%', style: ds.typography.labelMd.copyWith(color: c.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
