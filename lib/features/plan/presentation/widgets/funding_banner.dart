import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
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
    final first = warnings.first;
    final name = first.rule.note.isEmpty ? t.record.repeat.fallbackName : first.rule.note;
    final more = warnings.length > 1 ? ' ${t.plan.fundingMore(n: warnings.length - 1)}' : '';
    // Banner perhatian (prototipe `RencanaBulanIni.dc.html`): satu kalimat +
    // satu tindakan.
    return AppBanner(
      key: const ValueKey('funding-banner'),
      icon: IconKey.warning,
      message:
          '${t.plan.fundingBody(wallet: first.walletName, shortfall: AppMoneyFormatter.formatApprox(first.shortfall), name: name, date: CycleMonthFormatter.formatDayMonth(first.date))}$more',
      actionLabel: t.plan.fundingAction(wallet: first.walletName),
      onAction: () => onShowWallet(first.walletId),
    );
  }
}
