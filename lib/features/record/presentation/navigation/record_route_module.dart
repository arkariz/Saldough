import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/record/di/notification_capture_scope.dart';
import 'package:saldough/features/record/di/record_scope.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/bloc/record_state.dart';
import 'package:saldough/features/record/presentation/capture/notification/bloc/capture_inbox_bloc.dart';
import 'package:saldough/features/record/presentation/capture/notification/bloc/notification_settings_bloc.dart';
import 'package:saldough/features/record/presentation/capture/notification/capture_inbox_page.dart';
import 'package:saldough/features/record/presentation/capture/notification/notification_settings_page.dart';
import 'package:saldough/features/record/presentation/capture/open_voice_record.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/record/presentation/open_edit_transaction_sheet.dart';
import 'package:saldough/features/record/presentation/open_record_sheet.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `record` (ADR-030 §3.3).
///
/// Ketiga rutenya **alur transparan** (`RouteTransition.none`): rute tak
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
    RouteNode.typed<EmptyInput>(
      key: RecordRouteKeys.voice,
      transition: RouteTransition.none,
      defaultInput: () => const EmptyInput(),
      builder: (context, _) => const _RecordFlow(run: openVoiceRecord),
    ),
    RouteNode.typed<EmptyInput>(
      key: RecordRouteKeys.notificationSettings,
      defaultInput: () => const EmptyInput(),
      builder: (context, _) => _NotificationCapturePage(
        builder: (scope) => BlocProvider.value(
          value: scope.container<NotificationSettingsBloc>()..add(const NotificationSettingsStarted()),
          child: const EffectListener<NotificationSettingsBloc, NotificationSettingsState>(
            child: NotificationSettingsPage(),
          ),
        ),
      ),
    ),
    RouteNode.typed<EmptyInput>(
      key: RecordRouteKeys.captureInbox,
      defaultInput: () => const EmptyInput(),
      builder: (context, _) => _NotificationCapturePage(
        // Bloc setelan ikut dipasang: "Buat pola" menyimpan pola lewat bloc itu.
        builder: (scope) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: scope.container<CaptureInboxBloc>()..add(const CaptureInboxStarted())),
            BlocProvider.value(
              value: scope.container<NotificationSettingsBloc>()..add(const NotificationSettingsStarted()),
            ),
          ],
          child: const EffectListener<CaptureInboxBloc, CaptureInboxState>(child: CaptureInboxPage()),
        ),
      ),
    ),
  ];
}

/// Halaman Catat dari notifikasi: memasang `NotificationCaptureScope`.
class _NotificationCapturePage extends StatelessWidget {
  const _NotificationCapturePage({required this.builder});

  final Widget Function(NotificationCaptureScope scope) builder;

  @override
  Widget build(BuildContext context) {
    final parentContainer = ScopeProvider.of(context);
    return ScopeWidget<NotificationCaptureScope>(
      create: () => NotificationCaptureScope(parentContainer: parentContainer),
      builder: (context, scope) => builder(scope),
    );
  }
}

/// Rute alur: memasang `RecordScope`, menjalankan [run] sekali sesudah frame
/// pertama, lalu menutup rutenya dengan hasil [run].
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
        child: EffectListener<RecordBloc, RecordState>(child: _Runner(run: run)),
      ),
    );
  }
}

class _Runner extends StatefulWidget {
  const _Runner({required this.run});

  final Future<Object?> Function(BuildContext context) run;

  @override
  State<_Runner> createState() => _RunnerState();
}

class _RunnerState extends State<_Runner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final result = await widget.run(context);
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  // Tak terlihat: lembar dan dialog alur ini tampil di atasnya, layar
  // pemanggil tetap terlihat di belakangnya.
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
