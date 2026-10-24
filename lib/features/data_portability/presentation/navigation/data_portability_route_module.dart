import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/features/data_portability/domain/file_transfer.dart';
import 'package:saldough/features/data_portability/domain/restore_gateway.dart';
import 'package:saldough/features/data_portability/domain/restore_reboot.dart';
import 'package:saldough/features/data_portability/presentation/bloc/restore_bloc.dart';
import 'package:saldough/features/data_portability/presentation/bloc/restore_state.dart';
import 'package:saldough/features/data_portability/presentation/navigation/data_portability_route_keys.dart';
import 'package:saldough/features/data_portability/presentation/pages/restore_done_page.dart';
import 'package:saldough/features/data_portability/presentation/pages/restore_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `data_portability` (ADR-030 §3.3). [reboot] dikawat akar
/// komposisi (`AppReboot`) karena fitur tidak boleh mengimpor `lib/app/`.
final class DataPortabilityRouteModule extends FeatureRouteModule {
  /// Membuat [DataPortabilityRouteModule].
  const DataPortabilityRouteModule({required this.reboot});

  /// Memulai ulang aplikasi sesudah penggantian disiapkan.
  final RestoreReboot reboot;

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<RestoreInput>(
      key: DataPortabilityRouteKeys.restore,
      builder: (context, input) {
        final container = ScopeProvider.of(context);
        return BlocProvider(
          create: (_) => RestoreBloc(
            gateway: container<RestoreGateway>(),
            transfer: container<FileTransfer>(),
            reboot: reboot,
          )..add(RestoreStarted(bytes: input.bytes, source: input.source)),
          child: const EffectListener<RestoreBloc, RestoreState>(child: RestorePage()),
        );
      },
    ),
    RouteNode.typed<RestoreDoneInput>(
      key: DataPortabilityRouteKeys.restoreDone,
      builder: (context, input) => RestoreDonePage(
        report: input.report,
        statuses: ScopeProvider.of(context)<FeatureStatuses>(),
      ),
    ),
  ];
}
