import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';

/// Lencana "Plus" di ujung baris atau tombol yang dibatasi di Gratis
/// (komponen PlusBadge, ADR-041 §3.8). Hilang begitu paket Plus berlaku;
/// barisnya sendiri tetap bisa diketuk dan membuka paywall.
///
/// [when] membatasi kapan lencana tampil, mis. hanya bila batas Gratis sudah
/// tercapai (template ke-2); bawaannya selalu bagi yang bukan Plus.
class PlusBadge extends StatelessWidget {
  /// Membuat [PlusBadge].
  const PlusBadge({this.when, super.key});

  /// Syarat tambahan agar lencana tampil untuk paket [PlanState] bukan Plus.
  final bool Function()? when;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<PlanState>(
    valueListenable: ActivePlan.notifier,
    builder: (context, plan, _) => plan.isPlus || !(when?.call() ?? true) ? const SizedBox.shrink() : const _PlusPill(),
  );
}

/// Lencana Plus v2: pil `actionPrimary` tipis dengan bintang kecil.
class _PlusPill extends StatelessWidget {
  const _PlusPill();

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.actionPrimary.withValues(alpha: 0.12), borderRadius: DsRadius.fullAll),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 13, color: c.actionPrimary),
            const SizedBox(width: 3),
            Text(
              t.premium.plusBadge,
              style: context.ds.typography.labelMd.copyWith(fontSize: 11, color: c.actionPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
