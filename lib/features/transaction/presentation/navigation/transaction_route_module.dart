import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/transaction/di/transaction_scope.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_detail_page.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_list_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `transaction` (ADR-030 §3.3). Tiap rute memasang
/// `TransactionScope`-nya sendiri; tab Riwayat dan layar lain tetap segar
/// lewat `LedgerChanges` (ADR-030 §3.4).
final class TransactionRouteModule extends FeatureRouteModule {
  /// Membuat [TransactionRouteModule].
  const TransactionRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<TransactionDetailInput>(
      key: TransactionRouteKeys.detail,
      builder: (context, input) => _TransactionRoute(
        onStart: (bloc) => bloc.add(const TransactionStarted()),
        child: TransactionDetailPage(transaction: input.transaction),
      ),
    ),
    RouteNode.typed<TransactionHistoryInput>(
      key: TransactionRouteKeys.history,
      builder: (context, input) => _TransactionRoute(
        // `TransactionListPage` memicu `TransactionStarted` sendiri.
        onStart: (bloc) => bloc.add(TransactionWalletFilterChanged(input.walletId)),
        child: const TransactionListPage(),
      ),
    ),
  ];
}

class _TransactionRoute extends StatelessWidget {
  const _TransactionRoute({required this.onStart, required this.child});

  final void Function(TransactionBloc bloc) onStart;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parentContainer = ScopeProvider.of(context);
    return PixelTheme(
      child: ScopeWidget<TransactionScope>(
        create: () => TransactionScope(parentContainer: parentContainer),
        builder: (context, scope) {
          final bloc = scope.container<TransactionBloc>();
          return BlocProvider.value(
            value: bloc,
            child: EffectListener<TransactionBloc, TransactionState>(
              child: RunOnce(action: () => onStart(bloc), child: child),
            ),
          );
        },
      ),
    );
  }
}
