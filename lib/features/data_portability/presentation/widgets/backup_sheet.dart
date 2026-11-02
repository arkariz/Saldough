import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/count_formatter.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/data_portability/domain/backup_gateway.dart';
import 'package:saldough/features/data_portability/domain/backup_summary.dart';
import 'package:saldough/features/data_portability/domain/file_transfer.dart';
import 'package:saldough/features/data_portability/presentation/bloc/backup_bloc.dart';
import 'package:saldough/features/data_portability/presentation/bloc/backup_state.dart';
import 'package:saldough/features/data_portability/presentation/widgets/sheet_parts.dart';
import 'package:state_management/state_management.dart';

/// Membuka lembar **Cadangkan sekarang** (prototipe `LembarCadangkan.dc.html`).
Future<void> showBackupSheet(BuildContext context, GetIt container) => showAppSheet<void>(
  context,
  isScrollControlled: true,
  shape: fullScreenSheetShape,
  builder: (_) => BlocProvider(
    create: (_) =>
        BackupBloc(gateway: container<BackupGateway>(), transfer: container<FileTransfer>())
          ..add(const BackupStarted()),
    child: const EffectListener<BackupBloc, BackupState>(child: BackupSheet()),
  ),
);

/// Isi lembar cadangkan: ringkasan dan daftar yang ikut dan tidak, lalu proses
/// (bisa batal), lalu cadangan siap dengan Simpan ke… dan Bagikan.
class BackupSheet extends StatelessWidget {
  /// Membuat [BackupSheet].
  const BackupSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BackupBloc, BackupState>(
      listenWhen: (previous, current) => !previous.finished && current.finished,
      listener: (context, _) => Navigator.of(context).maybePop(),
      builder: (context, state) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(title: t.dataPortability.backupTitle),
              const SizedBox(height: 16),
              switch (state.phase) {
                BackupPhase.loading => const SheetLoading(),
                BackupPhase.form => _Form(summary: state.summary),
                BackupPhase.busy => SheetBusy(
                  message: t.dataPortability.backupBusy,
                  cancelKey: const ValueKey('backup-cancel'),
                  onCancel: () => context.read<BackupBloc>().add(const BackupCancelRequested()),
                ),
                BackupPhase.ready => SheetFileReady(
                  title: t.dataPortability.backupReady,
                  fileName: state.file!.name,
                  fileMeta: _countsText(state.file!.summary),
                  fileAsset: ClayIcons.backupBox,
                  notSavedText: t.dataPortability.backupNotSaved,
                  showNotSaved: state.notSaved,
                  saveKey: const ValueKey('backup-save'),
                  shareKey: const ValueKey('backup-share'),
                  onSave: () => context.read<BackupBloc>().add(const BackupSaveRequested()),
                  onShare: () => context.read<BackupBloc>().add(const BackupShareRequested()),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }

  /// "142 transaksi · 4 dompet".
  static String _countsText(BackupSummary summary) => t.dataPortability.backupFileMeta(
    transactions: t.dataPortability.countTransactions(
      n: summary.transactions,
      count: CountFormatter.format(summary.transactions),
    ),
    wallets: t.dataPortability.countWallets(n: summary.wallets, count: CountFormatter.format(summary.wallets)),
  );

  /// "142 transaksi, 4 dompet, sejak 3 Jun 2026".
  static String summaryText(BackupSummary summary) {
    final wallets = t.dataPortability.countWallets(n: summary.wallets, count: CountFormatter.format(summary.wallets));
    final first = summary.firstDate;
    if (summary.transactions == 0 || first == null) {
      return t.dataPortability.backupSummaryNoTransactions(wallets: wallets);
    }
    final since = DateTime.parse(first);
    return t.dataPortability.backupSummary(
      transactions: t.dataPortability.countTransactions(
        n: summary.transactions,
        count: CountFormatter.format(summary.transactions),
      ),
      wallets: wallets,
      since: CycleMonthFormatter.noBreak(CycleMonthFormatter.formatDateShort(since)),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.summary});

  final BackupSummary? summary;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary != null) ...[
          Semantics(
            liveRegion: true,
            child: DsCard(
              child: Row(
                children: [
                  DsIconTile.asset(asset: ClayIcons.backupBox, size: DsIconTileSize.sm),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      BackupSheet.summaryText(summary!),
                      style: ds.typography.bodyMd.copyWith(color: ds.colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Column(
                title: t.dataPortability.backupIncluded,
                items: t.dataPortability.backupIn,
                included: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Column(
                title: t.dataPortability.backupExcluded,
                items: t.dataPortability.backupOut,
                included: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SheetNote(t.dataPortability.backupHint),
        const SizedBox(height: 16),
        DsButton(
          key: const ValueKey('backup-go'),
          label: t.dataPortability.backupAction,
          expand: true,
          onPressed: () => context.read<BackupBloc>().add(const BackupRequested()),
        ),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.title, required this.items, required this.included});

  final String title;
  final List<String> items;
  final bool included;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DsCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ds.typography.titleMd.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    included ? Icons.check_circle_rounded : Icons.remove_circle_outline,
                    size: 16,
                    color: included ? c.income : c.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: ds.typography.bodySm.copyWith(color: included ? c.textPrimary : c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
