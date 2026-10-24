import 'package:flutter/widgets.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/app_badge.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';

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
    builder: (context, plan, _) => plan.isPlus || !(when?.call() ?? true)
        ? const SizedBox.shrink()
        : AppBadge(t.premium.plusBadge, tone: AppTone.brand, icon: IconKey.plus),
  );
}
