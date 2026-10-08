import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Banner **Siapkan dana** (PLAN_TAB_LAYOUT §4.1 blok 0, ADR-036 §3.6):
/// paling banyak satu, yang tanggalnya paling dekat, dengan "+n lainnya".
/// Warna peringatan **dan** ikon, bukan warna saja. Kalimatnya menyarankan
/// tindakan di luar aplikasi, tidak pernah menawarkan transfer.
class FundingBanner extends StatefulWidget {
  /// Membuat [FundingBanner]. [warnings] tidak kosong, urut tanggal.
  const FundingBanner({required this.warnings, required this.onShowWallet, super.key});

  /// Peringatan, urut tanggal.
  final List<FundingWarning> warnings;

  /// Membuka perkiraan dompet peringatan pertama.
  final ValueChanged<String> onShowWallet;

  @override
  State<FundingBanner> createState() => _FundingBannerState();
}

class _FundingBannerState extends State<FundingBanner> {
  @override
  void initState() {
    super.initState();
    AppAnalytics.log(PlanEvents.fundingWarningShown);
  }

  @override
  Widget build(BuildContext context) {
    final warnings = widget.warnings;
    final onShowWallet = widget.onShowWallet;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final first = warnings.first;
    final name = first.rule.note.isEmpty ? t.record.repeat.fallbackName : first.rule.note;
    return Container(
      key: const ValueKey('funding-banner'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: colors.tinted(colors.danger, 0.08),
        border: Border.all(color: colors.danger, width: 2),
        borderRadius: AppRadius.pixelSmAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(IconKey.info, size: 20, color: colors.danger),
              const SizedBox(width: AppSpacing.space1),
              Expanded(
                child: Text(
                  t.plan.fundingTitle,
                  style: transactionLabelStyle(context, color: colors.danger),
                ),
              ),
              if (warnings.length > 1) Text(t.plan.fundingMore(n: warnings.length - 1), style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            t.plan.fundingBody(
              wallet: first.walletName,
              shortfall: AppMoneyFormatter.formatApprox(first.shortfall),
              name: name,
              date: CycleMonthFormatter.formatDayMonth(first.date),
            ),
            style: textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () => onShowWallet(first.walletId),
            child: Text('${t.plan.fundingAction(wallet: first.walletName)} ›'),
          ),
        ],
      ),
    );
  }
}
