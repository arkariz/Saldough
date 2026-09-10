import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/cycle/di/cycle_scope.dart';
import 'package:saldough/features/cycle/presentation/bloc/cycle_bloc.dart';
import 'package:saldough/features/cycle/presentation/navigation/cycle_route_keys.dart';
import 'package:saldough/features/cycle/presentation/pages/cycle_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `cycle`.
final class CycleRouteModule extends FeatureRouteModule {
  /// Membuat [CycleRouteModule].
  const CycleRouteModule();

  @override
  List<RouteNode> get routes => [
        RouteNode.typed<CycleDetailInput>(
          key: CycleRouteKeys.detail,
          defaultInput: () => CycleDetailInput(cycleId: _currentCycleId()),
          builder: (context, input) {
            final parentContainer = ScopeProvider.of(context);
            return ScopeWidget<CycleScope>(
              create: () => CycleScope(parentContainer: parentContainer),
              builder: (context, scope) => BlocProvider.value(
                value: scope.container<CycleBloc>()..add(CycleOpened(input.cycleId)),
                child: CyclePage(cycleId: input.cycleId),
              ),
            );
          },
        ),
      ];

  static String _currentCycleId() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
