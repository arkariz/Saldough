import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/card/di/card_scope.dart';
import 'package:saldough/features/card/presentation/bloc/card_bloc.dart';
import 'package:saldough/features/card/presentation/navigation/card_route_keys.dart';
import 'package:saldough/features/card/presentation/pages/card_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `card`.
final class CardRouteModule extends FeatureRouteModule {
  /// Membuat [CardRouteModule].
  const CardRouteModule();

  @override
  List<RouteNode> get routes => [
        RouteNode.typed<EmptyInput>(
          key: CardRouteKeys.page,
          defaultInput: EmptyInput.new,
          builder: (context, input) {
            final parentContainer = ScopeProvider.of(context);
            return ScopeWidget<CardScope>(
              create: () => CardScope(parentContainer: parentContainer),
              builder: (context, scope) => BlocProvider.value(
                value: scope.container<CardBloc>()..add(const CardOpened()),
                child: const CardPage(),
              ),
            );
          },
        ),
      ];
}
