import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/premium/domain/plus_moments.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/features/premium/presentation/widgets/plus_tile.dart';

/// Kartu Plus di Beranda (design `PlusKartu`): satu kalimat, satu tombol, bisa
/// ditutup, paling banyak satu. Jenisnya: jatah tafsir cerdas habis (Gratis)
/// atau rekap nilai H-3 sebelum uji coba berakhir. Tidak menggambar apa pun
/// bila tidak ada momen. Contoh Penjaga menunggu fiturnya (B-44).
class PlusHomeCard extends StatefulWidget {
  /// Membuat [PlusHomeCard].
  const PlusHomeCard({required this.container, super.key});

  /// Container akar tempat [PlusMoments] terdaftar.
  final GetIt container;

  @override
  State<PlusHomeCard> createState() => _PlusHomeCardState();
}

class _PlusHomeCardState extends State<PlusHomeCard> {
  PlusCard? _card;

  PlusMoments? get _moments => widget.container.isRegistered<PlusMoments>() ? widget.container<PlusMoments>() : null;

  @override
  void initState() {
    super.initState();
    ActivePlan.notifier.addListener(_load);
    unawaited(_load());
  }

  @override
  void dispose() {
    ActivePlan.notifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final card = await _moments?.card();
    if (mounted && card != _card) setState(() => _card = card);
  }

  Future<void> _dismiss(PlusCard card) async {
    setState(() => _card = null);
    await _moments?.dismiss(card);
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    if (card == null) return const SizedBox.shrink();
    final texts = t.premium;
    final (title, sub, lines, trigger) = switch (card) {
      PlusContextCard(:final limit) => (
        texts.paywall.messages.reading.title(n: limit),
        texts.paywall.messages.reading.body,
        const <(int, String)>[],
        PaywallTrigger.smartQuota,
      ),
      PlusRecapCard(:final endsOn, :final start, :final recorded) => (
        texts.card.recapTitle(date: CycleMonthFormatter.formatDayMonth(endsOn)),
        texts.card.recapSince(date: CycleMonthFormatter.formatDayMonth(start)),
        [if (recorded > 0) (recorded, texts.card.recapRecorded)],
        PaywallTrigger.trialRecap,
      ),
    };
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Semantics(
        container: true,
        label: title,
        child: AppCard(
          key: const ValueKey('plus-home-card'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlusTile(card is PlusRecapCard ? IconKey.plus : IconKey.photoCamera, size: 32),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: textTheme.titleMedium),
                        Text(sub, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
                      ],
                    ),
                  ),
                ],
              ),
              for (final (n, text) in lines) ...[
                const SizedBox(height: AppSpacing.space2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(width: 44, child: Text('$n', style: textTheme.titleMedium)),
                    Expanded(child: Text(text, style: textTheme.bodyMedium)),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.space3),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  spacing: AppSpacing.space1,
                  children: [
                    AppButton.text(label: texts.paywall.later, small: true, onPressed: () => unawaited(_dismiss(card))),
                    AppButton(
                      label: texts.seePlus,
                      small: true,
                      onPressed: () => unawaited(context.pushRoute(PremiumRouteKeys.paywall, PaywallInput(trigger))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
