import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/flow_runner.dart';
import 'package:saldough/features/record/di/record_scope.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/bloc/record_state.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/record/presentation/open_edit_transaction_sheet.dart';
import 'package:saldough/features/record/presentation/open_record_sheet.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `record` (ADR-030 §3.3).
///
/// Kedua rutenya **alur transparan** (`RouteTransition.none`): rute tak
/// terlihat yang memegang `RecordScope`-nya sendiri, membuka lembar dan
/// dialognya persis seperti sebelumnya, lalu menutup dirinya. Dengan begitu
/// `RecordBloc` hidup sampai penyimpanan dan snackbar hasilnya selesai,
/// walau lembarnya sudah tertutup -- tugas yang dulu dipegang shell.
final class RecordRouteModule extends FeatureRouteModule {
  /// Membuat [RecordRouteModule].
  const RecordRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<RecordSheetInput>(
      key: RecordRouteKeys.sheet,
      transition: RouteTransition.none,
      builder: (context, input) => _RecordFlow(
        run: (context) => openRecordSheet(
          context,
          initialWalletId: input.initialWalletId,
          initialChoice: input.initialChoice,
          initialBudgetItemId: input.initialBudgetItemId,
          initialAmountSen: input.initialAmountSen,
          initialToWalletId: input.initialToWalletId,
          prefillFrom: input.prefillFrom,
          draft: input.draft,
          initialRepeat: input.repeat,
          makeRecurringFrom: input.makeRecurringFrom,
        ),
      ),
    ),
    RouteNode.typed<RecordEditInput>(
      key: RecordRouteKeys.edit,
      transition: RouteTransition.none,
      builder: (context, input) => _RecordFlow(
        run: (context) => openEditTransactionSheet(
          context,
          transaction: input.transaction,
          wallets: input.wallets,
          budgetItems: input.budgetItems,
          onCreateCategory: context.read<RecordBloc>().createCategory,
        ),
      ),
    ),
  ];
}

/// Rute alur: memasang `RecordScope`, lalu [FlowRunner] menjalankan [run].
class _RecordFlow extends StatelessWidget {
  const _RecordFlow({required this.run});

  final Future<Object?> Function(BuildContext context) run;

  @override
  Widget build(BuildContext context) {
    final parentContainer = ScopeProvider.of(context);
    return ScopeWidget<RecordScope>(
      create: () => RecordScope(parentContainer: parentContainer),
      builder: (context, scope) => BlocProvider.value(
        value: scope.container<RecordBloc>(),
        // Snackbar galat/berhasil `RecordBloc`; tetap tampil sesudah rute
        // ini tertutup karena `ScaffoldMessenger` milik aplikasi.
        child: EffectListener<RecordBloc, RecordState>(child: FlowRunner(run: run)),
      ),
    );
  }
}
