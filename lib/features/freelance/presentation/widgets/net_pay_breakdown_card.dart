import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    Widget row(String label, String value, {Color? color, bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: strong ? textTheme.titleSmall : textTheme.bodyMedium)),
          const SizedBox(width: AppSpacing.space1),
          // Nominal mengecil di layar sempit atau teks diperbesar.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                value,
                style: (strong ? context.numberStyles.amount : context.numberStyles.amountSm).copyWith(
                  color: color ?? colors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return TransactionSlab(
      color: colors.surface2,
      shadow: 2,
      child: Column(
        children: [
          row(t.freelance.grossPayLabel, AppMoneyFormatter.format(breakdown.grossPay)),
          for (final deduction in breakdown.deductions)
            row(
              describeDeduction(deduction.rule),
              '−${AppMoneyFormatter.format(deduction.amount)}',
              color: colors.ink,
            ),
          const Divider(height: AppSpacing.space4),
          row(
            t.freelance.netPayLabel,
            AppMoneyFormatter.format(breakdown.netPay),
            color: colors.positive,
            strong: true,
          ),
        ],
      ),
    );
  }
}
