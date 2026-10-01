import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/freelance/di/freelance_scope.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_bloc.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';
import 'package:saldough/features/freelance/presentation/navigation/freelance_route_keys.dart';
import 'package:saldough/features/freelance/presentation/pages/freelance_overview_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `freelance` (ADR-030 §3.3). Freelance bukan tujuan
/// navigasi bawah, jadi `FreelanceScope` hidup selama rute ini terbuka saja.
///
/// Pemanggil yang menampilkan saldo tidak perlu menyegarkan apa pun sesudah
/// rute ini ditutup: pembayaran diterima dicatat lewat `RecordTransaction`,
/// yang memancarkan `LedgerChanges` (ADR-030 §3.4).
final class FreelanceRouteModule extends FeatureRouteModule {
  /// Membuat [FreelanceRouteModule].
  const FreelanceRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<EmptyInput>(
      key: FreelanceRouteKeys.overview,
      defaultInput: () => const EmptyInput(),
      builder: (context, _) {
        final parentContainer = ScopeProvider.of(context);
        return ScopeWidget<FreelanceScope>(
          create: () => FreelanceScope(parentContainer: parentContainer),
          builder: (context, scope) => BlocProvider.value(
            value: scope.container<FreelanceBloc>(),
            child: const EffectListener<FreelanceBloc, FreelanceState>(child: FreelanceOverviewPage()),
          ),
        );
      },
    ),
  ];

  @override
  List<DevEntry> get devEntries => [
    DevEntry.typed<EmptyInput>(
      label: 'Ikhtisar Freelance',
      category: 'freelance',
      key: FreelanceRouteKeys.overview,
      inputFactory: () => const EmptyInput(),
    ),
  ];
}
