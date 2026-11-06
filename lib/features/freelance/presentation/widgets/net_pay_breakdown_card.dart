import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/freelance/domain/entities/net_pay_breakdown.dart';
import 'package:saldough/features/freelance/presentation/freelance_format.dart';

/// Rincian gaji kotor, tiap potongan, dan gaji bersih, terpisah
/// (FR-FRL-003).
class NetPayBreakdownCard extends StatelessWidget {
  /// Membuat [NetPayBreakdownCard].
  const NetPayBreakdownCard({required this.breakdown, super.key});

  /// Rincian yang ditampilkan.
  final NetPayBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    Widget row(String label, String value, {Color? color, bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong ? ds.typography.titleMd.copyWith(fontSize: 14) : ds.typography.bodyMd,
            ),
          ),
          const SizedBox(width: 8),
          // Nominal mengecil di layar sempit atau teks diperbesar.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                value,
                style: (strong ? ds.typography.amount : ds.typography.amountSm).copyWith(
                  color: color ?? c.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.baseAll),
      child: Column(
        children: [
          row(t.freelance.grossPayLabel, AppMoneyFormatter.format(breakdown.grossPay)),
          for (final deduction in breakdown.deductions)
            row(describeDeduction(deduction.rule), '−${AppMoneyFormatter.format(deduction.amount)}'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, thickness: 1, color: c.outlineSubtle),
          ),
          row(t.freelance.netPayLabel, AppMoneyFormatter.format(breakdown.netPay), color: c.income, strong: true),
        ],
      ),
    );
  }
}
