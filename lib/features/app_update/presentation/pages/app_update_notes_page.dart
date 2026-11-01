import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/app_update/domain/services/update_policy.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_state.dart';
import 'package:saldough/features/app_update/presentation/widgets/app_update_labels.dart';
import 'package:saldough/features/app_update/presentation/widgets/release_notes_view.dart';
import 'package:saldough/features/app_update/presentation/widgets/update_diagnostics.dart';
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
          appBar: AppBar(
            title: Text(t.account.version.label, style: context.ds.typography.headlineMd),
            centerTitle: false,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Tekan lama: panel diagnostik (jawaban mentah Play dan keputusan
                // pengumuman) untuk menelusuri banner yang tidak muncul.
                GestureDetector(
                  key: const ValueKey('app-update-notes-header-hold'),
                  behavior: HitTestBehavior.opaque,
                  onLongPress: () => unawaited(
                    showAppSheet<void>(
                      context,
                      isScrollControlled: true,
                      builder: (_) => UpdateDiagnosticsSheet(text: buildUpdateDiagnostics(state)),
                    ),
                  ),
                  child: _VersionHeader(state: state),
                ),
                const SizedBox(height: 24),
                DsSectionHeader(title: texts.whatsNew.titlePatch),
                const SizedBox(height: 8),
                if (state.installedNotes.isEmpty)
                  DsCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        DsIconTile.asset(asset: ClayIcons.emptyTray, size: DsIconTileSize.lg),
                        const SizedBox(height: 10),
                        Text(
                          texts.whatsNew.empty,
                          textAlign: TextAlign.center,
                          style: context.ds.typography.bodySm.copyWith(color: context.ds.colors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  for (final note in state.installedNotes) ...[
                    DsCard(
                      key: ValueKey('app-update-notes-${note.build}-${note.patch}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              releaseNoteVersion(note),
                              style: context.ds.typography.labelMd.copyWith(color: context.ds.colors.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ReleaseNoteGroups(groups: note.groups),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
          bottomNavigationBar: action == null ? null : DsStickyBar(child: action),
        );
      },
    );
  }

  /// Tombol keadaan: Perbarui bila tersedia, Pasang sekarang bila sudah
  /// diunduh; selain itu tidak ada.
  Widget? _action(AppUpdateState state, AppUpdateBloc bloc) {
    final texts = t.appUpdate.action;
    return switch (state.status) {
      VersionStatus.available => DsButton(
        key: const ValueKey('app-update-notes-update'),
        label: texts.update,
        expand: true,
        onPressed: state.busy
            ? null
            : () => bloc.add(const AppUpdateDownloadRequested(source: UpdateActionSource.account)),
      ),
      VersionStatus.downloaded => DsButton(
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
    final ds = context.ds;
    final c = ds.colors;
    final version = state.snapshot?.version;
    final status = versionStatusLabel(state.status);
    final tile = SettingIconTile(versionStatusIcon(state.status));
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        key: const ValueKey('app-update-notes-header'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.actionPrimary.withValues(alpha: 0.10), c.surfaceCard],
          ),
          borderRadius: DsRadius.xlAll,
          border: Border.all(color: c.outlineSubtle),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (state.status == VersionStatus.downloading) AppSpin(child: tile) else tile,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (version != null)
                      Text(versionValue(version), style: ds.typography.headlineMd.copyWith(fontSize: 22)),
                    if (status != null) Text(status, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
