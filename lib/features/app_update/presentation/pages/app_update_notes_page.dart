import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/app_update/domain/services/update_policy.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_state.dart';
import 'package:state_management/state_management.dart';

/// Layar "Apa yang baru" dari baris Versi aplikasi di Akun (APP_UPDATE F4,
/// §7): tindakan sesuai keadaan di atas, daftar catatan di bawahnya.
///
/// Tindakan mengikuti keadaan sebenarnya, bukan banner, sehingga pengguna yang
/// sudah menekan Nanti tetap punya jalan memperbarui. Daftar catatan diisi
/// di T-20.4; sebelum itu hanya keadaan kosong.
class AppUpdateNotesPage extends StatelessWidget {
  /// Membuat [AppUpdateNotesPage].
  const AppUpdateNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = t.appUpdate;
    return Scaffold(
      appBar: AppBar(title: Text(texts.whatsNew.titlePatch)),
      body: SafeArea(
        child: BlocBuilder<AppUpdateBloc, AppUpdateState>(
          buildWhen: (a, b) => a.status != b.status || a.busy != b.busy,
          builder: (context, state) {
            final bloc = context.read<AppUpdateBloc>();
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                ?_status(context, state, bloc),
                const SizedBox(height: AppSpacing.space6),
                AppEmptyState(title: texts.whatsNew.empty),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Pesan keadaan dan tombolnya; `null` bila tidak ada yang perlu dilakukan.
  Widget? _status(BuildContext context, AppUpdateState state, AppUpdateBloc bloc) {
    final texts = t.appUpdate;
    switch (state.status) {
      case VersionStatus.available:
        return _StatusCard(
          key: const ValueKey('app-update-notes-available'),
          message: texts.banner.storeAvailable,
          action: AppButton(
            label: texts.action.update,
            expand: true,
            loading: state.busy,
            onPressed: state.busy ? null : () => bloc.add(const AppUpdateDownloadRequested()),
          ),
        );
      case VersionStatus.downloading:
        return _StatusCard(key: const ValueKey('app-update-notes-downloading'), message: texts.banner.storeDownloading);
      case VersionStatus.downloaded:
        return _StatusCard(
          key: const ValueKey('app-update-notes-downloaded'),
          message: texts.banner.storeDownloaded,
          action: AppButton(
            label: texts.action.install,
            expand: true,
            onPressed: () => bloc.add(const AppUpdateInstallRequested()),
          ),
        );
      case VersionStatus.patchReady:
        return _StatusCard(key: const ValueKey('app-update-notes-patch'), message: texts.banner.patchReady);
      case VersionStatus.latest:
      case VersionStatus.unknown:
        return null;
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.message, this.action, super.key});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.ink)),
          if (action case final button?) ...[const SizedBox(height: AppSpacing.space3), button],
        ],
      ),
    );
  }
}
