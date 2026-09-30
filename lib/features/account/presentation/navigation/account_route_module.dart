import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/theme/theme.dart';
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
  /// Membuat [AccountRouteModule].
  const AccountRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<EmptyInput>(
      key: AccountRouteKeys.page,
      defaultInput: () => const EmptyInput(),
      builder: (context, _) {
        final parentContainer = ScopeProvider.of(context);
        return PixelTheme(
          child: ScopeWidget<AccountScope>(
            create: () => AccountScope(parentContainer: parentContainer),
            builder: (context, scope) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: scope.container<AccountBloc>()),
                BlocProvider.value(value: scope.container<CategoryManagerBloc>()),
              ],
              child: const EffectListener<AccountBloc, AccountState>(child: AccountPage()),
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
