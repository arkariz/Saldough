import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/premium/domain/plus_purchasing.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/features/premium/presentation/widgets/plus_subscription.dart';

/// Bagian Plus di layar Akun (design `AkunPlus`): satu baris status paket
/// ("Gratis", uji coba, aktif, tenggang, ditahan, penguji), "Kelola di Play
/// Store" bila ada langganan, dan "Pulihkan pembelian" yang selalu ada.
///
/// Dibaca dari [ActivePlan], jadi berubah sendiri saat paket berubah. Paket
/// (Tahunan/Bulanan) dan status "tidak diperpanjang" belum disimpan di cache
/// hak, jadi keterangan aktif hanya menyebut tanggal akhir periode.
class AccountPlusSection extends StatelessWidget {
  /// Membuat [AccountPlusSection]; [launch] untuk uji.
  const AccountPlusSection({required this.purchasing, this.launch = launchPlaySubscriptions, super.key});

  /// Pembelian, untuk memulihkan.
  final PlusPurchasing purchasing;

  /// Membuka alamat di luar aplikasi.
  final Future<bool> Function(Uri uri) launch;

  @override
  Widget build(BuildContext context) {
    final texts = t.premium.account;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(texts.section),
        ValueListenableBuilder<PlanState>(
          valueListenable: ActivePlan.notifier,
          builder: (context, plan, _) {
            final (sub, badge, tone, manage, features) = _describe(plan);
            return AppListCard(
              dividerIndent: AppListCard.iconIndent,
              children: [
                AppListRow(
                  key: const ValueKey('account-plus-row'),
                  compact: true,
                  leading: AppIcon(IconKey.plus, color: context.appColors.ink2),
                  title: texts.rowTitle,
                  subtitle: sub,
                  wrapSubtitle: true,
                  trailing: badge == null ? null : AppBadge(badge, tone: tone),
                  chevron: true,
                  onTap: () => unawaited(
                    features
                        ? context.pushRoute(PremiumRouteKeys.features, const PlusFeaturesInput())
                        : context.pushRoute(PremiumRouteKeys.paywall, const PaywallInput(PaywallTrigger.account)),
                  ),
                ),
                if (manage)
                  AppListRow(
                    key: const ValueKey('account-plus-manage'),
                    compact: true,
                    leading: AppIcon(IconKey.openInNew, color: context.appColors.ink2),
                    title: texts.manage,
                    chevron: true,
                    onTap: () => unawaited(launch(playSubscriptionsUri)),
                  ),
                AppListRow(
                  key: const ValueKey('account-plus-restore'),
                  compact: true,
                  leading: AppIcon(IconKey.restorePurchases, color: context.appColors.ink2),
                  title: texts.restore,
                  chevron: true,
                  onTap: () => unawaited(_restore(context)),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _restore(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await purchasing.restore();
    messenger.showSnackBar(SnackBar(content: Text(t.premium.account.restoreDone)));
  }

  /// `(keterangan, lencana, nada, tampilkan "Kelola", buka daftar fitur)`.
  (String, String?, AppTone, bool, bool) _describe(PlanState plan) {
    final texts = t.premium.account;
    String date(DateTime d) => CycleMonthFormatter.formatDateShort(d);
    return switch (plan) {
      FreePlan() => (texts.subFree, null, AppTone.brand, false, false),
      TrialPlan(:final endsOn) => (texts.subTrial(date: date(endsOn)), texts.badgeTrial, AppTone.brand, false, false),
      OnHoldPlan() => (texts.subOnHold, texts.badgeCheck, AppTone.warning, true, false),
      PlusPlan(:final inGrace, :final until) when inGrace => (
        until == null ? texts.subOnHold : texts.subGrace(date: date(until)),
        texts.badgeCheck,
        AppTone.warning,
        true,
        false,
      ),
      PlusPlan(:final source, :final until) when source != PlanSource.purchase => (
        until == null ? texts.subTesterOpen : texts.subTester(date: date(until)),
        t.premium.plusBadge,
        AppTone.brand,
        false,
        true,
      ),
      PlusPlan(:final until) => (
        until == null ? texts.subActiveOpen : texts.subActive(date: date(until)),
        t.premium.plusBadge,
        AppTone.brand,
        true,
        true,
      ),
    };
  }
}
