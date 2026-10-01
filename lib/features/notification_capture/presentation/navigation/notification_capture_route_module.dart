import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/notification_capture/di/notification_capture_scope.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/capture_inbox_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/navigation/notification_capture_route_keys.dart';
import 'package:saldough/features/notification_capture/presentation/pages/capture_inbox_page.dart';
import 'package:saldough/features/notification_capture/presentation/pages/notification_settings_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute fitur `notification_capture` (ADR-030 §3.3, ADR-033 §3.3).
/// Tiap halaman memasang `NotificationCaptureScope`-nya sendiri.
final class NotificationCaptureRouteModule extends FeatureRouteModule {
  /// Membuat [NotificationCaptureRouteModule].
  const NotificationCaptureRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<EmptyInput>(
      key: NotificationCaptureRouteKeys.settings,
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
      key: NotificationCaptureRouteKeys.inbox,
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
