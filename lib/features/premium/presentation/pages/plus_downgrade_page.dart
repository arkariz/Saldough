import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    final offer = data.offer;
    final deal = offer?.options.where((o) => o.kind == PlusPlanKind.yearlyIntro).firstOrNull;
    final changes = [
      if (data.sources > 1) (IconKey.inbox, texts.notifTitle, texts.notifSub(n: data.sources)),
      if (data.autoRules > 0) (IconKey.refresh, texts.autoTitle, texts.autoSub(n: data.autoRules)),
      (IconKey.budget, texts.analysisTitle, texts.analysisSub(n: data.freePeriods)),
    ];
    Widget rows(List<(IconKey, String, String)> items) => AppListCard(
      dividerIndent: AppListCard.iconIndent,
      children: [
        for (final (icon, title, sub) in items)
          AppListRow(
            compact: true,
            leading: AppIcon(icon, color: colors.ink2),
            title: title,
            subtitle: sub,
            wrapTitle: true,
            wrapSubtitle: true,
          ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: Text(texts.title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          Text(texts.intro, style: textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.space4),
          AppSectionHeader(texts.keepTitle),
          rows([
            (IconKey.checkCircle, texts.keepEntries, texts.keepEntriesSub),
            (IconKey.checkCircle, texts.keepCore, texts.keepCoreSub),
          ]),
          const SizedBox(height: AppSpacing.space4),
          AppSectionHeader(texts.changeTitle),
          rows(changes),
          if (deal != null) ...[
            const SizedBox(height: AppSpacing.space4),
            Semantics(
              container: true,
              child: AppCard(
                key: const ValueKey('downgrade-offer'),
                color: colors.brandSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.offer?.deadline case final until?)
                      Text(
                        texts.dealKicker(until: _until(until)),
                        style: textTheme.labelMedium?.copyWith(color: colors.brandInk),
                      ),
                    Text(deal.priceText, style: textTheme.headlineSmall),
                    Text(texts.dealLine(regular: deal.regularPriceText ?? deal.priceText), style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: AppStickyBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: deal == null ? texts.ctaPlain : texts.ctaDeal,
              expand: true,
              onPressed: () => unawaited(
                context.pushRoute(PremiumRouteKeys.paywall, const PaywallInput(PaywallTrigger.trialRecap)),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            AppButton.secondary(label: texts.free, expand: true, onPressed: () => Navigator.of(context).maybePop()),
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
