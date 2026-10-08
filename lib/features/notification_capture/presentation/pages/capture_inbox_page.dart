import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/capture_inbox_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/pages/notification_pattern_page.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:state_management/state_management.dart';

/// Kotak masuk Catat dari notifikasi (ADR-032 §3.6): tangkapan yang perlu
/// ditinjau (Catat membuka CATAT terisi; item hilang hanya bila tersimpan)
/// dan transaksi yang tercatat otomatis (Tinjau/Batalkan).
class CaptureInboxPage extends StatelessWidget {
  /// Membuat [CaptureInboxPage].
  const CaptureInboxPage({super.key});

  /// Catat lewat CATAT. Bila draf cocok dengan satu kemunculan rutin,
  /// CATAT terisi kategori dan catatan dari rutin (yang kosong saja) dan
  /// transaksinya tertaut ke kemunculan itu (ADR-035 §3.4).
  Future<void> _record(BuildContext context, CaptureInboxEntry entry, OccurrenceMatch? match) async {
    final bloc = context.read<CaptureInboxBloc>();
    final draft = entry.draft;
    final saved = await context.pushRoute<RecordSheetInput, bool>(
      RecordRouteKeys.sheet,
      match == null
          ? RecordSheetInput(draft: draft)
          : RecordSheetInput(
              draft: draft.copyWith(
                categoryId: draft.categoryId == null ? () => match.rule.categoryId : null,
                note: draft.note.trim().isEmpty ? match.rule.note : null,
              ),
              occurrenceRule: match.rule,
              occurrenceDate: match.date,
            ),
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
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                AppSectionLabel(
                  texts.inboxPendingTitle,
                  hint: state.pending.isEmpty ? null : '${state.pending.length}',
                ),
                const SizedBox(height: AppSpacing.space1),
                if (state.pending.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
                    child: Text(texts.inboxEmpty, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
                  ),
                for (final entry in state.pending)
                  _PendingCard(
                    entry: entry,
                    match: state.matches[entry.id],
                    onRecord: () => _record(context, entry, state.matches[entry.id]),
                    onDismiss: () => context.read<CaptureInboxBloc>().add(CaptureInboxDismissed(entry.id)),
                    onMakePattern: () => _makePattern(context, entry),
                  ),
                const SizedBox(height: AppSpacing.space6),
                AppSectionLabel(texts.inboxAutoTitle, hint: state.auto.isEmpty ? null : '${state.auto.length}'),
                const SizedBox(height: AppSpacing.space1),
                if (state.auto.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
                    child: Text(texts.inboxAutoEmpty, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
                  ),
                for (final entry in state.auto)
                  _AutoCard(entry: entry, onReview: () => _review(context, entry), onUndo: () => _undo(context, entry)),
                if (state.linked.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space6),
                  AppSectionLabel(t.recurring.linkedTitle, hint: '${state.linked.length}'),
                  for (final linked in state.linked)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
                      title: Text(linked.ruleName),
                      subtitle: Text(
                        '${AppMoneyFormatter.format(linked.amount)} · '
                        '${CycleMonthFormatter.formatDayMonth(linked.occurrenceDate)}',
                      ),
                      trailing: TextButton(
                        onPressed: () => context.read<CaptureInboxBloc>().add(CaptureInboxUnlinked(linked)),
                        child: Text(t.recurring.unlinkAction),
                      ),
                    ),
                ],
                const SizedBox(height: AppSpacing.space4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
                  child: Text(texts.inboxRetention, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
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
    required this.match,
    required this.onRecord,
    required this.onDismiss,
    required this.onMakePattern,
  });

  final CaptureInboxEntry entry;
  final OccurrenceMatch? match;
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
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: AppHardCard(
        padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space2, AppSpacing.space1, AppSpacing.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.space1),
                    child: _CaptureHeader(
                      icon: TransactionIcon(
                        kind: _transactionKind(entry.draft.kind),
                        categoryId: entry.draft.categoryId,
                        sourceIconId: entry.iconId,
                      ),
                      amountSen: amount,
                      color: _kindColor(context, entry.draft.kind),
                      meta: '${entry.appLabel} · ${CycleMonthFormatter.formatDateShort(entry.capturedAt)}',
                    ),
                  ),
                ),
                PopupMenuButton<void>(
                  tooltip: texts.moreActions,
                  icon: AppIcon(IconKey.moreVert, color: colors.ink2),
                  itemBuilder: (_) => [PopupMenuItem<void>(onTap: onMakePattern, child: Text(texts.makePatternAction))],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (entry.possibleDuplicate)
                    Text(texts.possibleDuplicate, style: textTheme.bodySmall?.copyWith(color: colors.danger)),
                  if (match case final m?)
                    Text(
                      t.recurring.matchLabel(
                        name: m.rule.note,
                        date: CycleMonthFormatter.formatDayMonth(m.date),
                      ),
                      style: textTheme.bodySmall?.copyWith(color: colors.positive),
                    ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space1),
                    Text(note, style: textTheme.bodyMedium),
                  ],
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    entry.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onDismiss, child: Text(texts.dismissAction)),
                const SizedBox(width: AppSpacing.space1),
                FilledButton(onPressed: onRecord, child: Text(texts.recordAction)),
                const SizedBox(width: AppSpacing.space2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// [TransactionIcon] (kategori + lencana notifikasi), nominal berwarna sesuai
/// jenis, dan baris sumber · tanggal.
class _CaptureHeader extends StatelessWidget {
  const _CaptureHeader({required this.icon, required this.amountSen, required this.color, required this.meta});

  final Widget icon;
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
        icon,
        const SizedBox(width: AppSpacing.space2 + TransactionIcon.badgeOverhang),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount == null ? t.notificationCapture.amountUnknown : AppMoneyFormatter.format(amount),
                style: textTheme.titleMedium?.copyWith(color: amount == null ? colors.ink2 : color),
              ),
              Text(meta, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
            ],
          ),
        ),
      ],
    );
  }
}

TransactionKind _transactionKind(DraftKind kind) => switch (kind) {
  DraftKind.income => TransactionKind.income,
  DraftKind.expense => TransactionKind.expense,
  DraftKind.transfer => TransactionKind.transfer,
};

Color? _kindColor(BuildContext context, DraftKind? kind) => switch (kind) {
  DraftKind.income => context.appColors.positive,
  DraftKind.expense => context.appColors.ink,
  DraftKind.transfer => context.appColors.ink2,
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
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: AppHardCard(
        padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space2, AppSpacing.space4, AppSpacing.space1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CaptureHeader(
              icon: TransactionIcon(
                kind: _transactionKind(entry.kind),
                categoryId: entry.categoryId,
                sourceIconId: entry.iconId,
              ),
              amountSen: entry.amountSen,
              color: _kindColor(context, entry.kind),
              meta: '${entry.appLabel} · ${CycleMonthFormatter.formatDateShort(entry.transactionDate)}',
            ),
            if (entry.note.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space1),
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
