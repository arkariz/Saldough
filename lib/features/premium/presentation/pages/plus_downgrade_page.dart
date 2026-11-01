import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/premium/domain/plus_moments.dart';
import 'package:saldough/features/premium/domain/purchase_models.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';

/// Layar sesudah uji coba Plus berakhir tanpa membeli (D-8, design
/// `PlusTurun`): "Yang tetap" dan "Yang berubah" dengan angka pemakai sendiri
/// (baris yang tidak berubah untuknya dilewati), kartu penawaran bila ada,
/// dan dua tombol sama besar. Tidak ada yang dihapus atau dikunci.
class PlusDowngradePage extends StatelessWidget {
  /// Membuat [PlusDowngradePage].
  const PlusDowngradePage({required this.data, super.key});

  /// Isi layar.
  final PlusDowngrade data;

  @override
  Widget build(BuildContext context) {
    final texts = t.premium.downgrade;
    final ds = context.ds;
    final c = ds.colors;
    final offer = data.offer;
    final deal = offer?.options.where((o) => o.kind == PlusPlanKind.yearlyIntro).firstOrNull;
    final changes = [
      if (data.sources > 1) (ClayIcons.bell, texts.notifTitle, texts.notifSub(n: data.sources)),
      if (data.autoRules > 0) (ClayIcons.repeat, texts.autoTitle, texts.autoSub(n: data.autoRules)),
      (ClayIcons.report, texts.analysisTitle, texts.analysisSub(n: data.freePeriods)),
    ];
    Widget rows(List<(String, String, String)> items, {bool keep = false}) => DsListCard(
      children: [
        for (final (asset, title, sub) in items)
          DsSettingRow(
            leading: DsIconTile.asset(asset: asset, tone: keep ? DsIconTileTone.income : DsIconTileTone.warning),
            title: title,
            subtitle: sub,
          ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: Text(texts.title, style: ds.typography.headlineMd), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(texts.intro, style: ds.typography.bodyMd.copyWith(color: c.textSecondary)),
          const SizedBox(height: 16),
          DsSectionHeader(title: texts.keepTitle),
          const SizedBox(height: 8),
          rows(keep: true, [
            (ClayIcons.done, texts.keepEntries, texts.keepEntriesSub),
            (ClayIcons.done, texts.keepCore, texts.keepCoreSub),
          ]),
          const SizedBox(height: 16),
          DsSectionHeader(title: texts.changeTitle),
          const SizedBox(height: 8),
          rows(changes),
          if (deal != null) ...[
            const SizedBox(height: 16),
            Semantics(
              container: true,
              child: DecoratedBox(
                key: const ValueKey('downgrade-offer'),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(c.heroSurface, Colors.white, 0.1)!,
                      Color.lerp(c.heroSurface, Colors.black, 0.4)!,
                    ],
                  ),
                  borderRadius: DsRadius.xlAll,
                  border: Border.all(color: c.heroBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      DsIconTile.asset(
                        asset: ClayIcons.tierCoin,
                        tone: DsIconTileTone.heroIncome,
                        size: DsIconTileSize.lg,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data.offer?.deadline case final until?)
                              Text(
                                texts.dealKicker(until: _until(until)),
                                style: ds.typography.labelMd.copyWith(color: c.onHeroMuted),
                              ),
                            Text(
                              deal.priceText,
                              style: ds.typography.headlineMd.copyWith(fontSize: 24, color: c.onHero),
                            ),
                            Text(
                              texts.dealLine(regular: deal.regularPriceText ?? deal.priceText),
                              style: ds.typography.bodySm.copyWith(color: c.onHeroMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: DsStickyBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsButton(
              label: deal == null ? texts.ctaPlain : texts.ctaDeal,
              expand: true,
              onPressed: () => unawaited(
                context.pushRoute(PremiumRouteKeys.paywall, const PaywallInput(PaywallTrigger.trialRecap)),
              ),
            ),
            const SizedBox(height: 8),
            DsButton.secondary(label: texts.free, expand: true, onPressed: () => Navigator.of(context).maybePop()),
          ],
        ),
      ),
    );
  }

  /// "26 Nov, 21.00" (id) atau "26 Nov, 9:00 pm" (en).
  static String _until(DateTime d) {
    final minute = d.minute.toString().padLeft(2, '0');
    final clock = LocaleSettings.currentLocale == AppLocale.en
        ? '${d.hour % 12 == 0 ? 12 : d.hour % 12}:$minute ${d.hour < 12 ? 'am' : 'pm'}'
        : '${d.hour.toString().padLeft(2, '0')}.$minute';
    return '${CycleMonthFormatter.formatDayMonth(d)}, $clock';
  }
}
