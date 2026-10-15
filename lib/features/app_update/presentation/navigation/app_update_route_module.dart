import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/app_update/presentation/navigation/app_update_route_keys.dart';
import 'package:saldough/features/app_update/presentation/pages/app_update_notes_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `app_update` (ADR-030 §3.3). Bloc-nya hidup di akar
/// (Beranda dan Akun memakai keadaan yang sama), jadi rute hanya
/// menyediakannya, tanpa lingkup sendiri.
final class AppUpdateRouteModule extends FeatureRouteModule {
  /// Membuat [AppUpdateRouteModule].
  const AppUpdateRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<EmptyInput>(
      key: AppUpdateRouteKeys.notes,
      defaultInput: () => const EmptyInput(),
      builder: (context, _) => BlocProvider.value(
        value: ScopeProvider.of(context)<AppUpdateBloc>(),
        child: const AppUpdateNotesPage(),
      ),
    ),
  ];

  @override
  List<DevEntry> get devEntries => [
    DevEntry.typed<EmptyInput>(
      label: 'Apa yang baru',
      category: 'app_update',
      key: AppUpdateRouteKeys.notes,
      inputFactory: () => const EmptyInput(),
    ),
  ];
}
