import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';
import 'package:saldough/features/app_update/domain/services/update_policy.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_state.dart';
import 'package:state_management/state_management.dart';

/// Pengumuman pembaruan di Beranda (APP_UPDATE F1, F2, §7; ADR-039,
/// ADR-043 §3.6). Tidak menggambar apa pun: melapor satu slide ke [board]
/// (carousel status), berlatar kuning dan paling depan. Tidak ada slide bila
/// fitur tidak terdaftar (platform lain, uji) atau tidak ada yang diumumkan.
/// Tur spotlight tidak perlu menyingkirkannya: slide hidup di dalam target
/// `homeStatus`.
///
/// Memicu pengecekan sesudah frame pertama dan setiap aplikasi kembali ke
/// depan, tanpa menunda pembukaan Beranda (B-13).
class AppUpdateBanner extends StatefulWidget {
  /// Membuat [AppUpdateBanner].
  const AppUpdateBanner({required this.container, required this.board, super.key});

  /// Container akar tempat bloc pembaruan terdaftar.
  final GetIt container;

  /// Papan status Beranda tujuan slide.
  final DsStatusBoard board;

  @override
  State<AppUpdateBanner> createState() => _AppUpdateBannerState();
}

class _AppUpdateBannerState extends State<AppUpdateBanner> with WidgetsBindingObserver {
  AppUpdateBloc? _bloc;

  @override
  void initState() {
    super.initState();
    if (!widget.container.isRegistered<AppUpdateBloc>()) return;
    _bloc = widget.container<AppUpdateBloc>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (mounted) _bloc?.add(const AppUpdateChecked());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  static const _statusId = 'app_update';

  @override
  Widget build(BuildContext context) {
    final bloc = _bloc;
    if (bloc == null) return const SizedBox.shrink();
    return BlocBuilder<AppUpdateBloc, AppUpdateState>(
      bloc: bloc,
      buildWhen: (a, b) =>
          a.announcement != b.announcement || a.busy != b.busy || a.availableVersion != b.availableVersion,
      builder: (context, state) {
        final texts = t.appUpdate;
        final version = state.availableVersion == null ? '' : 'v${state.availableVersion}';
        DsStatusSlideData slide({
          required IconData icon,
          required String title,
          String subtitle = '',
          bool busy = false,
          String? actionLabel,
          VoidCallback? onAction,
          String? dismissLabel,
          VoidCallback? onDismiss,
        }) => DsStatusSlideData(
          id: _statusId,
          icon: icon,
          asset: ClayIcons.rocket,
          title: title,
          subtitle: subtitle,
          busy: busy,
          actionLabel: actionLabel,
          onAction: onAction,
          dismissLabel: dismissLabel,
          onDismiss: onDismiss,
          attention: true,
          order: -3,
        );
        final data = switch (state.announcement) {
          UpdateAnnouncement.none => null,
          UpdateAnnouncement.storeAvailable => slide(
            icon: Icons.rocket_launch_outlined,
            title: texts.banner.storeAvailable,
            subtitle: version,
            actionLabel: texts.action.update,
            onAction: state.busy ? null : () => bloc.add(const AppUpdateDownloadRequested()),
            dismissLabel: texts.action.later,
            onDismiss: () => bloc.add(const AppUpdateDeferred()),
          ),
          UpdateAnnouncement.storeDownloading => slide(
            icon: Icons.sync,
            busy: true,
            title: texts.banner.storeDownloading,
            subtitle: texts.banner.storeDownloadingNote,
          ),
          UpdateAnnouncement.storeDownloaded => slide(
            icon: Icons.system_update_alt,
            title: texts.banner.storeDownloaded,
            subtitle: version,
            actionLabel: texts.action.install,
            onAction: () => bloc.add(const AppUpdateInstallRequested()),
          ),
          UpdateAnnouncement.patchReady => slide(
            icon: Icons.restart_alt,
            title: texts.banner.patchReady,
            subtitle: texts.banner.patchReadyNote,
            actionLabel: texts.action.ok,
            onAction: () => bloc.add(const AppUpdatePatchAcknowledged()),
          ),
        };
        if (data != null) {
          // Analitik: bloc menyaring supaya sekali per keadaan per sesi.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!bloc.isClosed) bloc.add(AppUpdateBannerShown(state.announcement));
          });
        }
        return DsStatusReport(board: widget.board, id: _statusId, data: data);
      },
    );
  }
}
