import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/app_update/domain/services/update_policy.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_state.dart';
import 'package:saldough/features/app_update/presentation/widgets/app_update_labels.dart';
import 'package:saldough/features/app_update/presentation/widgets/release_notes_view.dart';
import 'package:state_management/state_management.dart';

/// Halaman "Versi aplikasi" dari baris di Akun (APP_UPDATE F4, §7; prototipe
/// `VersiAplikasi.dc.html`): kartu kepala berisi versi dan keadaannya, bagian
/// "Apa yang baru", dan tombol pembaruan yang menempel di bawah.
///
/// Tombol mengikuti keadaan sebenarnya, bukan banner, sehingga pengguna yang
/// sudah menekan Nanti tetap punya jalan memperbarui. Daftar catatan diisi
/// di T-20.4; sebelum itu hanya keadaan kosong.
class AppUpdateNotesPage extends StatefulWidget {
  /// Membuat [AppUpdateNotesPage].
  const AppUpdateNotesPage({super.key});

  @override
  State<AppUpdateNotesPage> createState() => _AppUpdateNotesPageState();
}

class _AppUpdateNotesPageState extends State<AppUpdateNotesPage> {
  @override
  void initState() {
    super.initState();
    // Analitik: daftar catatan dibuka dari Akun (bloc melewati bila kosong).
    context.read<AppUpdateBloc>().add(const AppUpdateWhatsNewOpened(UpdateActionSource.account));
  }

  @override
  Widget build(BuildContext context) {
    final texts = t.appUpdate;
    return BlocBuilder<AppUpdateBloc, AppUpdateState>(
      buildWhen: (a, b) => a.snapshot != b.snapshot || a.busy != b.busy || a.installedNotes != b.installedNotes,
      builder: (context, state) {
        final bloc = context.read<AppUpdateBloc>();
        final action = _action(state, bloc);
        return Scaffold(
          appBar: AppBar(title: Text(t.account.version.label)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                _VersionHeader(state: state),
                const SizedBox(height: AppSpacing.space6),
                AppSectionHeader(texts.whatsNew.titlePatch),
                if (state.installedNotes.isEmpty)
                  AppEmptyState(title: texts.whatsNew.empty)
                else
                  for (final note in state.installedNotes) ...[
                    AppCard(
                      key: ValueKey('app-update-notes-${note.build}-${note.patch}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              releaseNoteVersion(note),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.appColors.ink2),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space3),
                          ReleaseNoteGroups(groups: note.groups),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                  ],
              ],
            ),
          ),
          bottomNavigationBar: action == null ? null : AppStickyBar(child: action),
        );
      },
    );
  }

  /// Tombol keadaan: Perbarui bila tersedia, Pasang sekarang bila sudah
  /// diunduh; selain itu tidak ada.
  Widget? _action(AppUpdateState state, AppUpdateBloc bloc) {
    final texts = t.appUpdate.action;
    return switch (state.status) {
      VersionStatus.available => AppButton(
        key: const ValueKey('app-update-notes-update'),
        label: texts.update,
        expand: true,
        loading: state.busy,
        onPressed: state.busy
            ? null
            : () => bloc.add(const AppUpdateDownloadRequested(source: UpdateActionSource.account)),
      ),
      VersionStatus.downloaded => AppButton(
        key: const ValueKey('app-update-notes-install'),
        label: texts.install,
        expand: true,
        onPressed: () => bloc.add(const AppUpdateInstallRequested(source: UpdateActionSource.account)),
      ),
      _ => null,
    };
  }
}

/// Kartu kepala `tk-whatsnew`: tile ikon keadaan, nilai versi, keterangan.
class _VersionHeader extends StatelessWidget {
  const _VersionHeader({required this.state});

  final AppUpdateState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final version = state.snapshot?.version;
    final status = versionStatusLabel(state.status);
    final icon = AppIcon(versionStatusIcon(state.status), color: colors.brandInk);
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('app-update-notes-header'),
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: ShapeDecoration(color: colors.brandSoft, shape: const PixelCornerBorder()),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: ShapeDecoration(color: colors.surface, shape: const PixelCornerBorder.small()),
              child: state.status == VersionStatus.downloading ? AppSpin(child: icon) : icon,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (version != null) Text(versionValue(version), style: textTheme.titleLarge),
                  if (status != null) Text(status, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
