import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/grocery/di/grocery_scope.dart';
import 'package:saldough/features/grocery/presentation/bloc/grocery_bloc.dart';
import 'package:saldough/features/grocery/presentation/navigation/grocery_route_keys.dart';
import 'package:saldough/features/grocery/presentation/pages/grocery_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `grocery`.
final class GroceryRouteModule extends FeatureRouteModule {
  /// Membuat [GroceryRouteModule].
  const GroceryRouteModule();

  @override
  List<RouteNode> get routes => [
        RouteNode.typed<EmptyInput>(
          key: GroceryRouteKeys.page,
          defaultInput: EmptyInput.new,
          builder: (context, input) {
            final parentContainer = ScopeProvider.of(context);
            return ScopeWidget<GroceryScope>(
              create: () => GroceryScope(parentContainer: parentContainer),
              builder: (context, scope) => BlocProvider.value(
                value: scope.container<GroceryBloc>()..add(const GroceryPlanLoaded()),
                child: const GroceryPage(),
              ),
            );
          },
        ),
      ];
}
