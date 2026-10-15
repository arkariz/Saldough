import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/analysis/presentation/navigation/analysis_route_keys.dart';
import 'package:saldough/features/analysis/presentation/pages/analysis_page.dart';
import 'package:saldough/features/analysis/presentation/widgets/analysis_host.dart';

/// Rute fitur `analysis` (ADR-030 §3.3): tiap rute memasang scope-nya sendiri.
final class AnalysisRouteModule extends FeatureRouteModule {
  /// Membuat [AnalysisRouteModule].
  const AnalysisRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<AnalysisInput>(
      key: AnalysisRouteKeys.open,
      builder: (context, input) => AnalysisHost(
        container: ScopeProvider.of(context),
        periodStart: input.periodStart,
        child: const AnalysisPage(),
      ),
    ),
  ];
}
