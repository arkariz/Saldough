import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/wallet/di/wallet_scope.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_activity_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/features/wallet/presentation/navigation/wallet_route_keys.dart';
import 'package:saldough/features/wallet/presentation/pages/wallet_detail_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `wallet` (ADR-030 §3.3). Rincian dompet memasang
/// `WalletScope`-nya sendiri: `WalletBloc` untuk dompetnya dan
/// `WalletActivityBloc` untuk riwayat bulan ini. Tab Dompet tetap segar
/// lewat `LedgerChanges` (ADR-030 §3.4).
final class WalletRouteModule extends FeatureRouteModule {
  /// Membuat [WalletRouteModule].
  const WalletRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<WalletDetailInput>(
      key: WalletRouteKeys.detail,
      builder: (context, input) {
        final parentContainer = ScopeProvider.of(context);
        return ScopeWidget<WalletScope>(
          create: () => WalletScope(parentContainer: parentContainer),
          builder: (context, scope) {
            final wallets = scope.container<WalletBloc>();
            final activity = scope.container<WalletActivityBloc>();
            return MultiBlocProvider(
              providers: [
                BlocProvider.value(value: wallets),
                BlocProvider.value(value: activity),
              ],
              child: EffectListener<WalletBloc, WalletState>(
                child: RunOnce(
                  action: () {
                    wallets.add(const WalletStarted());
                    activity.add(WalletActivityStarted(input.wallet.id));
                  },
                  child: WalletDetailPage(wallet: input.wallet),
                ),
              ),
            );
          },
        );
      },
    ),
  ];
}
