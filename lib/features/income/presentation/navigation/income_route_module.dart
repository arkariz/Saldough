import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/income/di/income_scope.dart';
import 'package:saldough/features/income/presentation/bloc/income_source_bloc.dart';
import 'package:saldough/features/income/presentation/navigation/income_route_keys.dart';
import 'package:saldough/features/income/presentation/pages/income_source_list_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `income`.
final class IncomeRouteModule extends FeatureRouteModule {
  /// Membuat [IncomeRouteModule].
  const IncomeRouteModule();

  @override
  List<RouteNode> get routes => [
        RouteNode.typed<EmptyInput>(
          key: IncomeRouteKeys.list,
          defaultInput: EmptyInput.new,
          builder: (context, input) {
            final parentContainer = ScopeProvider.of(context);
            return ScopeWidget<IncomeScope>(
              create: () => IncomeScope(parentContainer: parentContainer),
              builder: (context, scope) => BlocProvider.value(
                value: scope.container<IncomeSourceBloc>()..add(const IncomeSourcesLoaded()),
                child: const IncomeSourceListPage(),
              ),
            );
          },
        ),
      ];
}
