import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/app_update/domain/services/update_policy.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_state.dart';
import 'package:state_management/state_management.dart';

/// Banner pembaruan di slot Beranda (APP_UPDATE F1, F2, §7; ADR-039).
/// Disisipkan shell sebagai cadangan banner kotak masuk notifikasi, jadi
/// paling banyak satu banner tampil (B-2, B-3). Kosong bila fitur tidak
/// terdaftar (platform lain, uji), bila tidak ada yang diumumkan, atau
/// selama tur spotlight tampil.
///
/// Memicu pengecekan sesudah frame pertama dan setiap aplikasi kembali ke
/// depan, tanpa menunda pembukaan Beranda (B-13).
class AppUpdateBanner extends StatefulWidget {
  /// Membuat [AppUpdateBanner].
  const AppUpdateBanner({required this.container, super.key});

  /// Container akar tempat bloc pembaruan terdaftar.
  final GetIt container;

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

  @override
  Widget build(BuildContext context) {
    final bloc = _bloc;
    if (bloc == null) return const SizedBox.shrink();
    // Selama tur tampil, banner menyingkir supaya target sorot tidak bergeser.
    if (SpotlightHost.maybeOf(context)?.isActive ?? false) return const SizedBox.shrink();
    return BlocBuilder<AppUpdateBloc, AppUpdateState>(
      bloc: bloc,
      buildWhen: (a, b) => a.announcement != b.announcement || a.busy != b.busy,
      builder: (context, state) {
        final texts = t.appUpdate;
        final banner = switch (state.announcement) {
          UpdateAnnouncement.none => null,
          UpdateAnnouncement.storeAvailable => AppBanner(
            key: const ValueKey('app-update-store-available'),
            tone: AppTone.info,
            icon: IconKey.refresh,
            message: texts.banner.storeAvailable,
            actionLabel: texts.action.update,
            onAction: state.busy ? null : () => bloc.add(const AppUpdateDownloadRequested()),
            secondaryActionLabel: texts.action.later,
            onSecondaryAction: () => bloc.add(const AppUpdateDeferred()),
          ),
          UpdateAnnouncement.storeDownloading => AppBanner(
            key: const ValueKey('app-update-store-downloading'),
            tone: AppTone.info,
            icon: IconKey.refresh,
            message: texts.banner.storeDownloading,
          ),
          UpdateAnnouncement.storeDownloaded => AppBanner(
            key: const ValueKey('app-update-store-downloaded'),
            tone: AppTone.info,
            icon: IconKey.refresh,
            message: texts.banner.storeDownloaded,
            actionLabel: texts.action.install,
            onAction: () => bloc.add(const AppUpdateInstallRequested()),
          ),
          UpdateAnnouncement.patchReady => AppBanner(
            key: const ValueKey('app-update-patch-ready'),
            tone: AppTone.info,
            icon: IconKey.refresh,
            message: texts.banner.patchReady,
            actionLabel: texts.action.ok,
            onAction: () => bloc.add(const AppUpdatePatchAcknowledged()),
          ),
        };
        if (banner == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space6),
          child: banner,
        );
      },
    );
  }
}
