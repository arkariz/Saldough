import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/count_formatter.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/app_update/presentation/navigation/app_update_route_keys.dart';
import 'package:saldough/features/data_portability/domain/backup_summary.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';
import 'package:saldough/features/data_portability/presentation/bloc/restore_bloc.dart';
import 'package:saldough/features/data_portability/presentation/bloc/restore_state.dart';
import 'package:saldough/features/data_portability/presentation/widgets/restore_steps.dart';
import 'package:saldough/features/data_portability/presentation/widgets/sheet_parts.dart';
import 'package:state_management/state_management.dart';

/// Pulihkan dari cadangan (`Pulihkan.dc.html`): pratinjau perbandingan, dialog
/// penggantian, daftar langkah, dan halaman galat. Dibuka dari Akun › Data
/// kamu setelah berkas dipilih, atau untuk "Kembalikan data sebelum pemulihan".
class RestorePage extends StatelessWidget {
  /// Membuat [RestorePage].
  const RestorePage({super.key});

  Future<void> _confirm(BuildContext context, RestorePreview preview) async {
    final bloc = context.read<RestoreBloc>();
    // Dari onboarding belum ada data yang bisa hilang: tanpa peringatan
    // penggantian dan tanpa cadangan pengaman (EXPORT_BACKUP §7.3).
    if (preview.source == RestoreKind.onboarding) {
      bloc.add(const RestoreConfirmed());
      return;
    }
    final dataPortability = t.dataPortability;
    final message = [
      dataPortability.restoreConfirmBody,
      if (preview.isOlderThanCurrent)
        dataPortability.restoreOlder(
          date: CycleMonthFormatter.formatDateShort(preview.backupCreatedAt),
        ),
    ].join('\n\n');
    final confirmed = await showConfirmDelete(
      context,
      title: dataPortability.restoreConfirmTitle,
      message: message,
      confirmLabel: dataPortability.restoreConfirmAction,
    );
    if (confirmed) bloc.add(const RestoreConfirmed());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestoreBloc, RestoreState>(
      builder: (context, state) {
        final running = state.phase == RestorePhase.running;
        final title = running
            ? t.dataPortability.restoreRunTitle
            : state.source == RestoreKind.undo
            ? t.dataPortability.undoPageTitle
            : t.dataPortability.restoreTitle;
        return PopScope(
          // Sesudah penggantian dimulai tidak ada jalan kembali (R-4).
          canPop: !running,
          child: Scaffold(
            appBar: AppBar(
              title: Text(title, style: context.ds.typography.headlineMd),
              centerTitle: false,
              automaticallyImplyLeading: !running,
            ),
            body: SafeArea(
              child: switch (state.phase) {
                RestorePhase.inspecting => const Center(child: SheetLoading()),
                RestorePhase.preview => _Preview(
                  preview: state.session!.preview,
                  onNext: () => _confirm(context, state.session!.preview),
                ),
                RestorePhase.running => _Running(onboarding: state.source == RestoreKind.onboarding),
                RestorePhase.error => _Failure(kind: state.error ?? RestoreErrorKind.other),
              },
            ),
          ),
        );
      },
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.preview, required this.onNext});

  final RestorePreview preview;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final d = t.dataPortability;
    final undo = preview.source == RestoreKind.undo;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (preview.isOlderThanCurrent) ...[
                SheetNotice(
                  key: const ValueKey('restore-older-notice'),
                  message: d.restoreOlder(date: CycleMonthFormatter.formatDateShort(preview.backupCreatedAt)),
                ),
                const SizedBox(height: 16),
              ],
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _VsColumn(
                        kicker: undo ? d.kickSafety : d.kickBackup,
                        big: CycleMonthFormatter.formatDateShort(preview.backupCreatedAt),
                        summary: preview.backup,
                        asset: undo ? ClayIcons.restoreClock : ClayIcons.backupBox,
                        highlighted: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Center(child: Icon(Icons.arrow_forward_rounded, size: 20, color: c.actionPrimary)),
                    ),
                    Expanded(
                      child: _VsColumn(
                        kicker: d.kickNow,
                        big: d.nowLabel,
                        summary: preview.current,
                        asset: ClayIcons.walletNav,
                      ),
                    ),
                  ],
                ),
              ),
              if (preview.hasChanges) ...[
                const SizedBox(height: 16),
                DsSectionHeader(title: d.restoreChanges),
                const SizedBox(height: 8),
                DsListCard(
                  children: [
                    if (preview.newCurrency case final code?)
                      DsSettingRow(
                        leading: DsIconTile.asset(asset: ClayIcons.coins, size: DsIconTileSize.sm),
                        title: d.changeCurrency(code: code),
                      ),
                    if (preview.lostInboxDrafts > 0)
                      DsSettingRow(
                        leading: DsIconTile.asset(asset: ClayIcons.tray, size: DsIconTileSize.sm),
                        title: d.changeDrafts(n: preview.lostInboxDrafts),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(d.restoreUnchanged, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
              ),
            ],
          ),
        ),
        DsStickyBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DsButton(key: const ValueKey('restore-next'), label: d.restoreNext, expand: true, onPressed: onNext),
              const SizedBox(height: 4),
              DsButton.ghost(
                key: const ValueKey('restore-cancel'),
                label: d.cancel,
                expand: true,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Satu kolom perbandingan: ubin clay, penanda, judul besar, dan empat baris.
/// Kolom cadangan diberi garis aksi supaya terbaca sebagai "yang akan dipasang".
class _VsColumn extends StatelessWidget {
  const _VsColumn({
    required this.kicker,
    required this.big,
    required this.summary,
    required this.asset,
    this.highlighted = false,
  });

  final String kicker;
  final String big;
  final BackupSummary summary;
  final String asset;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final d = t.dataPortability;
    final first = summary.firstDate;
    final lines = [
      d.countTransactions(n: summary.transactions, count: CountFormatter.format(summary.transactions)),
      d.countWallets(n: summary.wallets, count: CountFormatter.format(summary.wallets)),
      if (first != null) d.since(date: CycleMonthFormatter.formatDateShort(DateTime.parse(first))),
      summary.currency ?? 'IDR',
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: DsRadius.lgAll,
        border: highlighted ? Border.all(color: c.actionPrimary, width: 1.5) : null,
      ),
      child: DsCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DsIconTile.asset(asset: asset, size: DsIconTileSize.sm),
            const SizedBox(height: 8),
            Text(kicker, style: ds.typography.labelMd.copyWith(color: c.textSecondary)),
            const SizedBox(height: 2),
            Text(big, style: ds.typography.titleMd),
            const SizedBox(height: 8),
            for (final line in lines) Text(line, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _Running extends StatelessWidget {
  const _Running({required this.onboarding});

  final bool onboarding;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SheetHeroTile(asset: ClayIcons.hourglass),
        const SizedBox(height: 16),
        // Langkah 1 (menyimpan cadangan pengaman) berjalan di halaman ini;
        // langkah berikutnya di layar boot ulang. Dari onboarding tanpa langkah 1.
        RestoreSteps(labels: restoreStepLabels(onboarding: onboarding), current: 1),
        const SizedBox(height: 12),
        Text(
          t.dataPortability.restoreNoCancel,
          textAlign: TextAlign.center,
          style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.kind});

  final RestoreErrorKind kind;

  @override
  Widget build(BuildContext context) {
    final d = t.dataPortability;
    final (asset, title, body) = switch (kind) {
      RestoreErrorKind.invalid => (ClayIcons.warning, d.errorInvalidTitle, d.errorInvalidBody),
      RestoreErrorKind.newer => (ClayIcons.rocket, d.errorNewerTitle, d.errorNewerBody),
      RestoreErrorKind.space => (ClayIcons.warning, d.errorSpaceTitle, d.errorSpaceBody),
      RestoreErrorKind.other => (ClayIcons.warning, d.errorOtherTitle, d.errorOtherBody),
    };
    final ds = context.ds;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SheetHeroTile(
                    asset: asset,
                    tone: kind == RestoreErrorKind.newer ? DsIconTileTone.info : DsIconTileTone.warning,
                  ),
                  const SizedBox(height: 16),
                  Text(title, textAlign: TextAlign.center, style: ds.typography.headlineMd.copyWith(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        DsStickyBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (kind == RestoreErrorKind.newer)
                DsButton(
                  key: const ValueKey('restore-update'),
                  label: d.updateApp,
                  expand: true,
                  onPressed: () => context.pushRoute(AppUpdateRouteKeys.notes, const EmptyInput()),
                )
              else
                DsButton(
                  key: const ValueKey('restore-other-file'),
                  label: d.chooseOtherFile,
                  expand: true,
                  onPressed: () => context.read<RestoreBloc>().add(const RestoreOtherFileRequested()),
                ),
              const SizedBox(height: 4),
              DsButton.ghost(
                key: const ValueKey('restore-close'),
                label: d.close,
                expand: true,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
