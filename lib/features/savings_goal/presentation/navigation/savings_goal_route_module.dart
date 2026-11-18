import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/savings_goal/di/savings_goal_scope.dart';
import 'package:saldough/features/savings_goal/presentation/bloc/savings_goal_bloc.dart';
import 'package:saldough/features/savings_goal/presentation/navigation/savings_goal_route_keys.dart';
import 'package:saldough/features/savings_goal/presentation/pages/savings_goal_detail_page.dart';
import 'package:saldough/features/savings_goal/presentation/pages/savings_goal_form_page.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:state_management/state_management.dart';

/// Rute fitur tujuan tabungan (ADR-048 §3.8); tiap rute memasang
/// [SavingsGoalScope] sendiri (ADR-030).
final class SavingsGoalRouteModule extends FeatureRouteModule {
  /// Membuat [SavingsGoalRouteModule].
  const SavingsGoalRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<SavingsGoalDetailInput>(
      key: SavingsGoalRouteKeys.detail,
      builder: (context, input) => _scoped(context, (_) => SavingsGoalDetailPage(goalId: input.goalId)),
    ),
    RouteNode.typed<SavingsGoalFormInput>(
      key: SavingsGoalRouteKeys.form,
      builder: (context, input) => _scoped(
        context,
        (scope) => SavingsGoalFormPage(initial: input.goal, draftStore: scope.container<SavingsGoalDraftStore>()),
      ),
    ),
  ];

  static Widget _scoped(BuildContext context, Widget Function(SavingsGoalScope scope) page) {
    final parentContainer = ScopeProvider.of(context);
    return ScopeWidget<SavingsGoalScope>(
      create: () => SavingsGoalScope(parentContainer: parentContainer),
      builder: (context, scope) {
        final bloc = scope.container<SavingsGoalBloc>();
        return BlocProvider.value(
          value: bloc,
          child: EffectListener<SavingsGoalBloc, SavingsGoalState>(
            child: RunOnce(action: () => bloc.add(const SavingsGoalStarted()), child: page(scope)),
          ),
        );
      },
    );
  }
}
