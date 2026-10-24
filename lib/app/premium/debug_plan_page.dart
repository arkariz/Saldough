import 'package:di/di.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/app/premium/plan_override.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Kunci rute halaman paket uji; hanya terdaftar di build non-rilis.
const debugPlanRouteKey = RouteKey<EmptyInput>('app.debugPlan');

/// Modul rute halaman paket uji (ADR-041 §3.10). Milik `lib/app/` karena
/// hanya perlakuan pengembang, bukan fitur: di rilis tidak punya rute maupun
/// entri menu pengembang.
final class DebugPlanRouteModule extends FeatureRouteModule {
  /// Membuat [DebugPlanRouteModule]; [isRelease] untuk uji.
  const DebugPlanRouteModule({this.isRelease = kReleaseMode});

  /// Build rilis: tanpa rute dan tanpa entri.
  final bool isRelease;

  @override
  List<RouteNode> get routes => isRelease
      ? const []
      : [
          RouteNode.typed<EmptyInput>(
            key: debugPlanRouteKey,
            defaultInput: () => const EmptyInput(),
            builder: (context, _) =>
                DebugPlanPage(container: ScopeProvider.of(context)),
          ),
        ];

  @override
  List<DevEntry> get devEntries => isRelease
      ? const []
      : [
          DevEntry.typed<EmptyInput>(
            label: 'Paket Plus (uji)',
            category: 'premium',
            key: debugPlanRouteKey,
            inputFactory: () => const EmptyInput(),
          ),
        ];
}

/// Memilih paket uji: Otomatis (hak sebenarnya), Gratis, Uji coba, atau Plus.
/// Menampilkan keadaan paket yang sedang berlaku.
class DebugPlanPage extends StatelessWidget {
  /// Membuat [DebugPlanPage].
  const DebugPlanPage({required this.container, super.key});

  /// Kontainer akar.
  final GetIt container;

  static const Map<PlanOverride, (String, String)> _labels = {
    PlanOverride.auto: (
      'Otomatis',
      'Hak sebenarnya (akun, uji coba, RevenueCat)',
    ),
    PlanOverride.free: ('Gratis', 'Paksa Gratis meski hak ada'),
    PlanOverride.trial: ('Uji coba', 'Uji coba yang berakhir besok'),
    PlanOverride.plus: ('Plus', 'Plus tanpa batas waktu'),
  };

  @override
  Widget build(BuildContext context) {
    final controller = container<PlanOverrideController>();
    final entitlements = container<Entitlements>();
    return Scaffold(
      appBar: AppBar(title: const Text('Paket Plus (uji)')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => StreamBuilder<PlanState>(
            stream: entitlements.changes,
            initialData: entitlements.current,
            builder: (context, snapshot) => ListView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                Text(
                  'Berlaku: ${_describe(snapshot.data ?? entitlements.current)}',
                  key: const ValueKey('plan-now'),
                ),
                const SizedBox(height: AppSpacing.space4),
                AppListCard(
                  children: [
                    for (final option in PlanOverride.values)
                      AppListRow(
                        key: ValueKey('plan-${option.name}'),
                        title: _labels[option]!.$1,
                        subtitle: _labels[option]!.$2,
                        trailing: controller.value == option
                            ? const AppIcon(IconKey.check)
                            : null,
                        onTap: () => controller.select(option),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _describe(PlanState state) => switch (state) {
    FreePlan() => 'Gratis',
    TrialPlan(:final endsOn) =>
      'Uji coba sampai ${endsOn.year}-${endsOn.month}-${endsOn.day}',
    PlusPlan(:final source) => 'Plus (${source.name})',
    OnHoldPlan() => 'Ditahan',
  };
}
