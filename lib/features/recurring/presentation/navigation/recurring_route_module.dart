import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/recurring/di/recurring_scope.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_state.dart';
import 'package:saldough/features/recurring/presentation/navigation/recurring_route_keys.dart';
import 'package:saldough/features/recurring/presentation/pages/recurring_detail_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `recurring` (ADR-030 §3.3). Rincian rutin memasang
/// `RecurringScope`-nya sendiri dengan riwayat setahun; segmen Rutin segar
/// lewat `RecurringChanges`.
final class RecurringRouteModule extends FeatureRouteModule {
  /// Membuat [RecurringRouteModule].
  const RecurringRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<RecurringDetailInput>(
      key: RecurringRouteKeys.detail,
      builder: (context, input) {
        final parentContainer = ScopeProvider.of(context);
        return ScopeWidget<RecurringScope>(
          create: () => RecurringScope(parentContainer: parentContainer, monthsBack: 12),
          builder: (context, scope) {
            final bloc = scope.container<RecurringBloc>();
            return BlocProvider.value(
              value: bloc,
              child: EffectListener<RecurringBloc, RecurringState>(
                child: RunOnce(
                  action: () => bloc.add(const RecurringStarted()),
                  child: RecurringDetailPage(ruleId: input.ruleId),
                ),
              ),
            );
          },
        );
      },
    ),
  ];
}
