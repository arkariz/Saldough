import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
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
    final ds = context.ds;
    final items = [
      (IconKey.photoCamera, texts.records.title, texts.records.text),
      (IconKey.notificationsActive, texts.watches.title, texts.watches.text),
      (IconKey.chatBubble, texts.answers.title, texts.answers.text),
      (IconKey.trendingUp, texts.plans.title, texts.plans.text),
      (IconKey.summarize, texts.reports.title, texts.reports.text),
      (IconKey.backup, texts.keeps.title, texts.keeps.text),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(texts.title, style: ds.typography.headlineMd), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        children: [
          Text(texts.intro, style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary)),
          const SizedBox(height: 16),
          DsListCard(
            children: [
              for (final (icon, title, text) in items)
                DsSettingRow(leading: PlusTile(icon, size: 40), title: title, subtitle: text),
            ],
          ),
          const SizedBox(height: 16),
          DsCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DsIconTile.asset(asset: ClayIcons.done, size: DsIconTileSize.sm),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(texts.freeTitle, style: ds.typography.titleMd),
                      Text(texts.free, style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary)),
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
            : DsStickyBar(
                child: DsButton(
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
