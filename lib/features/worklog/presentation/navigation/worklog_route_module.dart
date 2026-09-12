import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/worklog/di/worklog_scope.dart';
import 'package:saldough/features/worklog/presentation/bloc/worklog_bloc.dart';
import 'package:saldough/features/worklog/presentation/navigation/worklog_route_keys.dart';
import 'package:saldough/features/worklog/presentation/pages/worklog_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `worklog`.
final class WorklogRouteModule extends FeatureRouteModule {
  /// Membuat [WorklogRouteModule].
  const WorklogRouteModule();

  @override
  List<RouteNode> get routes => [
        RouteNode.typed<WorklogSourceInput>(
          key: WorklogRouteKeys.page,
          defaultInput: WorklogSourceInput.new,
          builder: (context, input) {
            final parentContainer = ScopeProvider.of(context);
            return ScopeWidget<WorklogScope>(
              create: () => WorklogScope(parentContainer: parentContainer),
              builder: (context, scope) => BlocProvider.value(
                value: scope.container<WorklogBloc>()..add(WorklogOpened(initialSourceId: input.sourceId)),
                child: const WorklogPage(),
              ),
            );
          },
        ),
      ];
}
