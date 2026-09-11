import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/investment/di/investment_scope.dart';
import 'package:saldough/features/investment/presentation/bloc/investment_bloc.dart';
import 'package:saldough/features/investment/presentation/navigation/investment_route_keys.dart';
import 'package:saldough/features/investment/presentation/pages/investment_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `investment`.
final class InvestmentRouteModule extends FeatureRouteModule {
  /// Membuat [InvestmentRouteModule].
  const InvestmentRouteModule();

  @override
  List<RouteNode> get routes => [
        RouteNode.typed<EmptyInput>(
          key: InvestmentRouteKeys.page,
          defaultInput: EmptyInput.new,
          builder: (context, input) {
            final parentContainer = ScopeProvider.of(context);
            return ScopeWidget<InvestmentScope>(
              create: () => InvestmentScope(parentContainer: parentContainer),
              builder: (context, scope) => BlocProvider.value(
                value: scope.container<InvestmentBloc>()..add(const InvestmentOpened()),
                child: const InvestmentPage(),
              ),
            );
          },
        ),
      ];
}
