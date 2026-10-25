import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/features/premium/presentation/widgets/plus_subscription.dart';
import 'package:saldough/features/premium/presentation/widgets/plus_tile.dart';

/// "Yang dikerjakan Plus" (design `FiturPlus`): enam pilar, kartu "Tetap
/// gratis", dan tombol "Lihat paket". Dibuka dari paywall dan dari Akun.
class PlusFeaturesPage extends StatelessWidget {
  /// Membuat [PlusFeaturesPage].
  const PlusFeaturesPage({this.fromPaywall = false, super.key});

  /// Dibuka dari paywall: "Lihat paket" kembali ke sana, bukan membuka lagi.
  final bool fromPaywall;

  @override
  Widget build(BuildContext context) {
    final texts = t.premium.features;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    final items = [
      (IconKey.photoCamera, texts.records.title, texts.records.text),
      (IconKey.notificationsActive, texts.watches.title, texts.watches.text),
      (IconKey.chatBubble, texts.answers.title, texts.answers.text),
      (IconKey.trendingUp, texts.plans.title, texts.plans.text),
      (IconKey.summarize, texts.reports.title, texts.reports.text),
      (IconKey.backup, texts.keeps.title, texts.keeps.text),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(texts.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          0,
          AppSpacing.space4,
          AppSpacing.space4,
        ),
        children: [
          Text(texts.intro, style: textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.space4),
          AppListCard(
            dividerIndent: 60,
            children: [
              for (final (icon, title, text) in items)
                AppListRow(
                  leading: PlusTile(icon, size: 32),
                  title: title,
                  subtitle: text,
                  wrapTitle: true,
                  wrapSubtitle: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(IconKey.checkCircle, color: colors.ink2),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(texts.freeTitle, style: textTheme.titleMedium),
                      Text(
                        texts.free,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<PlanState>(
        valueListenable: ActivePlan.notifier,
        // Sudah berlangganan: tidak ada paket untuk dilihat.
        builder: (context, plan, _) => isSubscribed(plan)
            ? const SizedBox.shrink()
            : AppStickyBar(
                child: AppButton(
                  label: texts.cta,
                  expand: true,
                  onPressed: () => fromPaywall
                      ? Navigator.of(context).pop()
                      : context.pushRoute(
                          PremiumRouteKeys.paywall,
                          const PaywallInput(PaywallTrigger.account),
                        ),
                ),
              ),
      ),
    );
  }
}
