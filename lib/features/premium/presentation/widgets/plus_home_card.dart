import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
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
    final ds = context.ds;
    final c = ds.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        container: true,
        label: title,
        child: DsCard(
          key: const ValueKey('plus-home-card'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlusTile(card is PlusRecapCard ? IconKey.plus : IconKey.photoCamera, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: ds.typography.titleMd),
                        Text(sub, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              for (final (n, text) in lines) ...[
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.mdAll),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        SizedBox(width: 44, child: Text('$n', style: ds.typography.amount.copyWith(fontSize: 20))),
                        Expanded(
                          child: Text(text, style: ds.typography.bodySm.copyWith(color: c.textPrimary)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  spacing: 4,
                  children: [
                    DsButton.ghost(label: texts.paywall.later, onPressed: () => unawaited(_dismiss(card))),
                    DsButton(
                      label: texts.seePlus,
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
