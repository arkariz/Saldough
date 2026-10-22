import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/app_update/presentation/navigation/app_update_route_keys.dart';
import 'package:saldough/features/data_portability/domain/backup_summary.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';
import 'package:saldough/features/data_portability/presentation/bloc/restore_bloc.dart';
import 'package:saldough/features/data_portability/presentation/bloc/restore_state.dart';
import 'package:saldough/features/data_portability/presentation/widgets/restore_steps.dart';
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
            appBar: AppBar(title: Text(title), automaticallyImplyLeading: !running),
            body: SafeArea(
              child: switch (state.phase) {
                RestorePhase.inspecting => const Center(child: CircularProgressIndicator()),
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final d = t.dataPortability;
    final undo = preview.source == RestoreKind.undo;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.space4),
            children: [
              if (preview.isOlderThanCurrent) ...[
                AppBanner(
                  message: d.restoreOlder(date: CycleMonthFormatter.formatDateShort(preview.backupCreatedAt)),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _VsColumn(
                        kicker: undo ? d.kickSafety : d.kickBackup,
                        big: CycleMonthFormatter.formatDateShort(preview.backupCreatedAt),
                        summary: preview.backup,
                      ),
                    ),
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
                      height: 128,
                      color: colors.line,
                    ),
                    Expanded(
                      child: _VsColumn(kicker: d.kickNow, big: d.nowLabel, summary: preview.current),
                    ),
                  ],
                ),
              ),
              if (preview.hasChanges) ...[
                const SizedBox(height: AppSpacing.space4),
                AppSectionHeader(d.restoreChanges),
                const SizedBox(height: AppSpacing.space2),
                AppListCard(
                  children: [
                    if (preview.newCurrency case final code?)
                      AppListRow(
                        compact: true,
                        leading: AppIcon(IconKey.payments, color: colors.ink2),
                        title: d.changeCurrency(code: code),
                        wrapTitle: true,
                      ),
                    if (preview.lostInboxDrafts > 0)
                      AppListRow(
                        compact: true,
                        leading: AppIcon(IconKey.inbox, color: colors.ink2),
                        title: d.changeDrafts(n: preview.lostInboxDrafts),
                        wrapTitle: true,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
                child: Text(d.restoreUnchanged, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
              ),
            ],
          ),
        ),
        AppStickyBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(key: const ValueKey('restore-next'), label: d.restoreNext, expand: true, onPressed: onNext),
              const SizedBox(height: AppSpacing.space1),
              AppButton.text(
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

/// Satu kolom perbandingan (`tk-vs__col`): penanda, judul besar, dan empat baris.
class _VsColumn extends StatelessWidget {
  const _VsColumn({required this.kicker, required this.big, required this.summary});

  final String kicker;
  final String big;
  final BackupSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final d = t.dataPortability;
    final first = summary.firstDate;
    final lines = [
      d.countTransactions(n: summary.transactions),
      d.countWallets(n: summary.wallets),
      if (first != null) d.since(date: CycleMonthFormatter.formatDateShort(DateTime.parse(first))),
      summary.currency ?? 'IDR',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kicker, style: textTheme.labelMedium?.copyWith(color: colors.ink2)),
        const SizedBox(height: AppSpacing.space1),
        Text(big, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.space2),
        for (final line in lines) Text(line, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
      ],
    );
  }
}

class _Running extends StatelessWidget {
  const _Running({required this.onboarding});

  final bool onboarding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        // Langkah 1 (menyimpan cadangan pengaman) berjalan di halaman ini;
        // langkah berikutnya di layar boot ulang. Dari onboarding tanpa langkah 1.
        RestoreSteps(labels: restoreStepLabels(onboarding: onboarding), current: 1),
        const SizedBox(height: AppSpacing.space3),
        Text(
          t.dataPortability.restoreNoCancel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.ink2),
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
    final (icon, title, body) = switch (kind) {
      RestoreErrorKind.invalid => (IconKey.error, d.errorInvalidTitle, d.errorInvalidBody),
      RestoreErrorKind.newer => (IconKey.appUpdate, d.errorNewerTitle, d.errorNewerBody),
      RestoreErrorKind.space => (IconKey.error, d.errorSpaceTitle, d.errorSpaceBody),
      RestoreErrorKind.other => (IconKey.error, d.errorOtherTitle, d.errorOtherBody),
    };
    final colors = context.appColors;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.brandSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.space4),
                      child: AppIcon(icon, color: colors.brandInk, size: 32),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.ink2),
                  ),
                ],
              ),
            ),
          ),
        ),
        AppStickyBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (kind == RestoreErrorKind.newer)
                AppButton(
                  key: const ValueKey('restore-update'),
                  label: d.updateApp,
                  expand: true,
                  onPressed: () => context.pushRoute(AppUpdateRouteKeys.notes, const EmptyInput()),
                )
              else
                AppButton(
                  key: const ValueKey('restore-other-file'),
                  label: d.chooseOtherFile,
                  expand: true,
                  onPressed: () => context.read<RestoreBloc>().add(const RestoreOtherFileRequested()),
                ),
              const SizedBox(height: AppSpacing.space1),
              AppButton.text(
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
