import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/budget/di/budget_scope.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_state.dart';
import 'package:saldough/features/budget/presentation/navigation/budget_route_keys.dart';
import 'package:saldough/features/budget/presentation/pages/budget_detail_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `budget` (ADR-030 §3.3). Rincian anggaran memasang
/// `BudgetScope`-nya sendiri; tab Anggaran menyegarkan dirinya sesudah rute
/// ini ditutup, dan progres ikut `LedgerChanges` (ADR-030 §3.4).
final class BudgetRouteModule extends FeatureRouteModule {
  /// Membuat [BudgetRouteModule].
  const BudgetRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<BudgetDetailInput>(
      key: BudgetRouteKeys.detail,
      builder: (context, input) {
        final parentContainer = ScopeProvider.of(context);
        return ScopeWidget<BudgetScope>(
          create: () => BudgetScope(parentContainer: parentContainer),
          builder: (context, scope) {
            final bloc = scope.container<BudgetBloc>();
            return BlocProvider.value(
              value: bloc,
              child: EffectListener<BudgetBloc, BudgetState>(
                child: RunOnce(
                  action: () => bloc.add(const BudgetStarted()),
                  child: BudgetDetailPage(budgetId: input.budgetId),
                ),
              ),
            );
          },
        );
      },
    ),
  ];
}
