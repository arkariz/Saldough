import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/account/di/account_scope.dart';
import 'package:saldough/features/account/presentation/bloc/account_bloc.dart';
import 'package:saldough/features/account/presentation/bloc/account_state.dart';
import 'package:saldough/features/account/presentation/bloc/category_manager_bloc.dart';
import 'package:saldough/features/account/presentation/navigation/account_route_keys.dart';
import 'package:saldough/features/account/presentation/pages/account_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `account` (ADR-030 §3.3): layar Akun lengkap dengan
/// `AccountScope`-nya sendiri (ADR-023).
final class AccountRouteModule extends FeatureRouteModule {
  /// Membuat [AccountRouteModule]; [versionEntry] mengisi baris Versi
  /// aplikasi (dikawat akar komposisi, isinya milik fitur `app_update`) dan
  /// [dataSection] bagian Data kamu (milik fitur `data_portability`).
  const AccountRouteModule({this.versionEntry, this.dataSection, this.plusSection});

  /// Pembuat baris Versi aplikasi dari container akar.
  final Widget Function(GetIt container)? versionEntry;

  /// Pembuat bagian Data kamu (ekspor, cadangkan, pulihkan) dari container akar.
  final Widget Function(GetIt container)? dataSection;

  /// Pembuat bagian Plus (milik fitur `premium`) dari container akar.
  final Widget Function(GetIt container)? plusSection;

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<EmptyInput>(
      key: AccountRouteKeys.page,
      defaultInput: () => const EmptyInput(),
      builder: (context, _) {
        final parentContainer = ScopeProvider.of(context);
        return ScopeWidget<AccountScope>(
          create: () => AccountScope(parentContainer: parentContainer),
          builder: (context, scope) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: scope.container<AccountBloc>()),
              BlocProvider.value(value: scope.container<CategoryManagerBloc>()),
            ],
            child: EffectListener<AccountBloc, AccountState>(
              child: AccountPage(
                versionEntry: versionEntry?.call(parentContainer),
                dataSection: dataSection?.call(parentContainer),
                plusSection: plusSection?.call(parentContainer),
              ),
            ),
          ),
        );
      },
    ),
  ];

  @override
  List<DevEntry> get devEntries => [
    DevEntry.typed<EmptyInput>(
      label: 'Akun',
      category: 'account',
      key: AccountRouteKeys.page,
      inputFactory: () => const EmptyInput(),
    ),
  ];
}
