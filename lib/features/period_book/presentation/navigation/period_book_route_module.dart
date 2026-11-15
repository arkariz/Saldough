import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/period_book/presentation/navigation/period_book_route_keys.dart';
import 'package:saldough/features/period_book/presentation/pages/ritual_page.dart';
import 'package:saldough/features/period_book/presentation/period_book_ritual_access.dart';

/// Modul rute fitur `period_book` (ADR-030 §3.3). Gerbang, ingatan, dan sumber
/// data hidup di akar; rute hanya menyediakannya lewat [PeriodBookRitualAccess].
final class PeriodBookRouteModule extends FeatureRouteModule {
  /// Membuat [PeriodBookRouteModule].
  const PeriodBookRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<RitualInput>(
      key: PeriodBookRouteKeys.ritual,
      defaultInput: () => const RitualInput(periodId: ''),
      builder: (context, input) => RitualPage(
        access: ScopeProvider.of(context)<PeriodBookRitualAccess>(),
        periodId: input.periodId,
      ),
    ),
  ];

  @override
  List<DevEntry> get devEntries => const [];
}
