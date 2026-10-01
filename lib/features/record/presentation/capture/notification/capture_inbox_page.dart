import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/record/domain/capture/interpreted_transaction.dart';
import 'package:saldough/features/record/domain/capture/notification/capture_inbox_entry.dart';
import 'package:saldough/features/record/presentation/capture/notification/bloc/capture_inbox_bloc.dart';
import 'package:saldough/features/record/presentation/capture/notification/bloc/notification_settings_bloc.dart';
import 'package:saldough/features/record/presentation/capture/notification/notification_pattern_page.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:state_management/state_management.dart';

/// Kotak masuk Catat dari notifikasi (ADR-032 §3.6): tangkapan yang perlu
/// ditinjau (Catat membuka CATAT terisi; item hilang hanya bila tersimpan)
/// dan transaksi yang tercatat otomatis (Tinjau/Batalkan).
class CaptureInboxPage extends StatelessWidget {
  /// Membuat [CaptureInboxPage].
  const CaptureInboxPage({super.key});

  Future<void> _record(BuildContext context, CaptureInboxEntry entry) async {
    final bloc = context.read<CaptureInboxBloc>();
    final saved = await context.pushRoute<RecordSheetInput, bool>(
      RecordRouteKeys.sheet,
      RecordSheetInput(draft: entry.draft),
    );
    if (saved ?? false) bloc.add(CaptureInboxRecorded(entry.id));
  }

  Future<void> _makePattern(BuildContext context, CaptureInboxEntry entry) async {
    final inbox = context.read<CaptureInboxBloc>();
    final settings = context.read<NotificationSettingsBloc>();
    final pattern = await openNotificationPatternPage(
      context,
      packageName: entry.packageName,
      wallets: settings.state.wallets,
      sample: entry.text,
    );
    if (pattern == null) return;
    settings.add(NotificationPatternSaved(pattern));
    await settings.stream.firstWhere((s) => s.userPatterns.contains(pattern));
    await inbox.reinterpret(entry.id);
  }

  Future<void> _review(BuildContext context, AutoRecordedEntry entry) async {
    final transaction = await context.read<CaptureInboxBloc>().findTransaction(entry);
    if (transaction == null || !context.mounted) return;
    await context.pushRoute(TransactionRouteKeys.detail, TransactionDetailInput(transaction));
  }

  Future<void> _undo(BuildContext context, AutoRecordedEntry entry) async {
    final bloc = context.read<CaptureInboxBloc>();
    final confirmed = await showConfirmDelete(
      context,
      title: t.notificationCapture.undoConfirmTitle,
      message: t.notificationCapture.undoConfirm,
      confirmLabel: t.notificationCapture.undoAction,
    );
    if (confirmed) bloc.add(CaptureInboxUndone(entry));
  }

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(title: Text(texts.inboxTitle)),
      body: SafeArea(
        child: BlocBuilder<CaptureInboxBloc, CaptureInboxState>(
          builder: (context, state) {
            if (state.isLoading) return const AppSkeletonPage();
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                AppSectionLabel(
                  texts.inboxPendingTitle,
                  hint: state.pending.isEmpty ? null : '${state.pending.length}',
                ),
                const SizedBox(height: AppSpacing.xs),
                if (state.pending.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: Text(texts.inboxEmpty, style: textTheme.bodyMedium?.copyWith(color: colors.textMuted)),
                  ),
                for (final entry in state.pending)
                  _PendingCard(
                    entry: entry,
                    onRecord: () => _record(context, entry),
                    onDismiss: () => context.read<CaptureInboxBloc>().add(CaptureInboxDismissed(entry.id)),
                    onMakePattern: () => _makePattern(context, entry),
                  ),
                const SizedBox(height: AppSpacing.lg),
                AppSectionLabel(texts.inboxAutoTitle, hint: state.auto.isEmpty ? null : '${state.auto.length}'),
                const SizedBox(height: AppSpacing.xs),
                if (state.auto.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: Text(texts.inboxAutoEmpty, style: textTheme.bodyMedium?.copyWith(color: colors.textMuted)),
                  ),
                for (final entry in state.auto)
                  _AutoCard(entry: entry, onReview: () => _review(context, entry), onUndo: () => _undo(context, entry)),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Text(texts.inboxRetention, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.entry,
    required this.onRecord,
    required this.onDismiss,
    required this.onMakePattern,
  });

  final CaptureInboxEntry entry;
  final VoidCallback onRecord;
  final VoidCallback onDismiss;
  final VoidCallback onMakePattern;

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    final amount = entry.draft.amountSen;
    final note = entry.draft.note.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppHardCard(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: _CaptureHeader(
                      icon: entry.icon,
                      appLabel: entry.appLabel,
                      amountSen: amount,
                      color: _kindColor(context, entry.draft.kind),
                      meta: '${entry.appLabel} · ${CycleMonthFormatter.formatDateShort(entry.capturedAt)}',
                    ),
                  ),
                ),
                PopupMenuButton<void>(
                  tooltip: texts.moreActions,
                  icon: Icon(Icons.more_vert, color: colors.textMuted),
                  itemBuilder: (_) => [PopupMenuItem<void>(onTap: onMakePattern, child: Text(texts.makePatternAction))],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (entry.possibleDuplicate)
                    Text(texts.possibleDuplicate, style: textTheme.bodySmall?.copyWith(color: colors.overBudget)),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(note, style: textTheme.bodyMedium),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    entry.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onDismiss, child: Text(texts.dismissAction)),
                const SizedBox(width: AppSpacing.xs),
                FilledButton(onPressed: onRecord, child: Text(texts.recordAction)),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ikon tangkapan, nominal (berwarna sesuai jenis), dan baris sumber · tanggal.
class _CaptureHeader extends StatelessWidget {
  const _CaptureHeader({
    required this.icon,
    required this.appLabel,
    required this.amountSen,
    required this.color,
    required this.meta,
  });

  final Uint8List? icon;
  final String appLabel;
  final int? amountSen;
  final Color? color;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    final amount = amountSen;
    return Row(
      children: [
        _CaptureIcon(icon: icon, appLabel: appLabel),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount == null ? t.notificationCapture.amountUnknown : AppMoneyFormatter.format(amount),
                style: textTheme.titleMedium?.copyWith(color: amount == null ? colors.textMuted : color),
              ),
              Text(meta, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ikon dari notifikasinya (logo bank/merchant); tanpa ikon, huruf awal
/// nama aplikasi.
class _CaptureIcon extends StatelessWidget {
  const _CaptureIcon({required this.icon, required this.appLabel});

  static const _size = 40.0;

  final Uint8List? icon;
  final String appLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final png = icon;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: AppRadius.pixelSmAll,
        child: SizedBox.square(
          dimension: _size,
          child: png == null
              ? ColoredBox(
                  color: colors.surfaceMid,
                  child: Center(
                    child: Text(
                      appLabel.trim().isEmpty ? '?' : appLabel.trim().characters.first.toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.textMuted),
                    ),
                  ),
                )
              : Image.memory(
                  png,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => ColoredBox(color: colors.surfaceMid),
                ),
        ),
      ),
    );
  }
}

Color? _kindColor(BuildContext context, DraftKind? kind) => switch (kind) {
  DraftKind.income => context.appColors.income,
  DraftKind.expense => context.appColors.expense,
  DraftKind.transfer => context.appColors.transfer,
  null => null,
};

class _AutoCard extends StatelessWidget {
  const _AutoCard({required this.entry, required this.onReview, required this.onUndo});

  final AutoRecordedEntry entry;
  final VoidCallback onReview;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppHardCard(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CaptureHeader(
              icon: entry.icon,
              appLabel: entry.appLabel,
              amountSen: entry.amountSen,
              color: _kindColor(context, entry.kind),
              meta: '${entry.appLabel} · ${CycleMonthFormatter.formatDateShort(entry.transactionDate)}',
            ),
            if (entry.note.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(entry.note, style: textTheme.bodyMedium),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onUndo, child: Text(texts.undoAction)),
                TextButton(onPressed: onReview, child: Text(texts.reviewAction)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
