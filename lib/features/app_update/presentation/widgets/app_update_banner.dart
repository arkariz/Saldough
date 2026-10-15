import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/app_update/domain/services/update_policy.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_state.dart';
import 'package:saldough/features/app_update/presentation/widgets/update_banner_card.dart';
import 'package:state_management/state_management.dart';

/// Banner pembaruan di slot Beranda (APP_UPDATE F1, F2, §7; ADR-039).
/// Disisipkan shell di slot **di atas** kartu saldo (rupa v3); tampil bersama
/// banner kotak masuk notifikasi, yang punya slot sendiri di bawah saldo
/// (B-2 diubah pemilik 15 Okt 2026). Kosong bila fitur tidak
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
      buildWhen: (a, b) =>
          a.announcement != b.announcement || a.busy != b.busy || a.availableVersion != b.availableVersion,
      builder: (context, state) {
        final texts = t.appUpdate;
        final chip = state.availableVersion == null ? null : 'v${state.availableVersion}';
        final banner = switch (state.announcement) {
          UpdateAnnouncement.none => null,
          UpdateAnnouncement.storeAvailable => UpdateBannerCard(
            key: const ValueKey('app-update-store-available'),
            emoji: '🚀',
            title: texts.banner.storeAvailable,
            versionChip: chip,
            actionLabel: texts.action.update,
            onAction: state.busy ? null : () => bloc.add(const AppUpdateDownloadRequested()),
            dismissLabel: texts.action.later,
            onDismiss: () => bloc.add(const AppUpdateDeferred()),
          ),
          UpdateAnnouncement.storeDownloading => UpdateBannerCard(
            key: const ValueKey('app-update-store-downloading'),
            icon: IconKey.progressActivity,
            spin: true,
            title: texts.banner.storeDownloading,
            description: texts.banner.storeDownloadingNote,
            versionChip: chip,
          ),
          UpdateAnnouncement.storeDownloaded => UpdateBannerCard(
            key: const ValueKey('app-update-store-downloaded'),
            title: texts.banner.storeDownloaded,
            versionChip: chip,
            actionLabel: texts.action.install,
            onAction: () => bloc.add(const AppUpdateInstallRequested()),
          ),
          UpdateAnnouncement.patchReady => UpdateBannerCard(
            key: const ValueKey('app-update-patch-ready'),
            icon: IconKey.restartAlt,
            title: texts.banner.patchReady,
            description: texts.banner.patchReadyNote,
            actionLabel: texts.action.ok,
            onAction: () => bloc.add(const AppUpdatePatchAcknowledged()),
          ),
        };
        if (banner == null) return const SizedBox.shrink();
        // Analitik: bloc menyaring supaya sekali per keadaan per sesi.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!bloc.isClosed) bloc.add(AppUpdateBannerShown(state.announcement));
        });
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space6),
          child: banner,
        );
      },
    );
  }
}
