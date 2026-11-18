import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/investment/di/investment_scope.dart';
import 'package:saldough/features/investment/presentation/bloc/investment_bloc.dart';
import 'package:saldough/features/investment/presentation/navigation/investment_route_keys.dart';
import 'package:saldough/features/investment/presentation/pages/investment_detail_page.dart';
import 'package:saldough/features/investment/presentation/pages/investment_form_page.dart';
import 'package:saldough/features/investment/presentation/pages/investment_values_page.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:state_management/state_management.dart';

/// Rute fitur investasi (ADR-049 §3.10–§3.11); tiap rute memasang
/// [InvestmentScope] sendiri (ADR-030).
final class InvestmentRouteModule extends FeatureRouteModule {
  /// Membuat [InvestmentRouteModule].
  const InvestmentRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<InvestmentDetailInput>(
      key: InvestmentRouteKeys.detail,
      builder: (context, input) => _scoped(context, (_) => InvestmentDetailPage(instrumentId: input.instrumentId)),
    ),
    RouteNode.typed<InvestmentFormInput>(
      key: InvestmentRouteKeys.form,
      builder: (context, input) => _scoped(
        context,
        (scope) => InvestmentFormPage(initial: input.instrument, draftStore: scope.container<InstrumentDraftStore>()),
      ),
    ),
    RouteNode.typed<InvestmentValuesInput>(
      key: InvestmentRouteKeys.values,
      builder: (context, input) => _scoped(context, (_) => InvestmentValuesPage(onlyId: input.onlyId)),
    ),
  ];

  static Widget _scoped(BuildContext context, Widget Function(InvestmentScope scope) page) {
    final parentContainer = ScopeProvider.of(context);
    return ScopeWidget<InvestmentScope>(
      create: () => InvestmentScope(parentContainer: parentContainer),
      builder: (context, scope) {
        final bloc = scope.container<InvestmentBloc>();
        return BlocProvider.value(
          value: bloc,
          child: EffectListener<InvestmentBloc, InvestmentState>(
            child: RunOnce(action: () => bloc.add(const InvestmentStarted()), child: page(scope)),
          ),
        );
      },
    );
  }
}
