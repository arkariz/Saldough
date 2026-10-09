import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/capture_inbox_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/navigation/notification_capture_route_keys.dart';
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
  Widget build(BuildContext context) => const _InboxBody();
}

enum _InboxTab { pending, auto }

/// Isi kotak masuk (prototipe `KotakMasuk.dc.html`): segmen "Perlu dicek" /
/// "Tercatat otomatis" dengan hitungan, kartu tangkapan, dan daftar yang
/// tercatat otomatis.
class _InboxBody extends StatefulWidget {
  const _InboxBody();

  @override
  State<_InboxBody> createState() => _InboxBodyState();
}

class _InboxBodyState extends State<_InboxBody> {
  _InboxTab _tab = _InboxTab.pending;

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    const page = CaptureInboxPage();
    return Scaffold(
      appBar: AppBar(
        title: Text(texts.inboxTitle),
        actions: [
          AppIconButton(
            icon: IconKey.filter,
            label: texts.settingsTitle,
            onPressed: () => context.pushRoute(NotificationCaptureRouteKeys.settings, const EmptyInput()),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<CaptureInboxBloc, CaptureInboxState>(
          builder: (context, state) {
            if (state.isLoading) return const AppSkeletonPage();
            final inbox = context.read<CaptureInboxBloc>();
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.space4, 0, AppSpacing.space4, AppSpacing.space8),
              children: [
                AppSegmentedControl<_InboxTab>(
                  options: [(_InboxTab.pending, texts.inboxPendingTitle), (_InboxTab.auto, texts.inboxAutoTitle)],
                  selected: _tab,
                  counts: {_InboxTab.pending: state.pending.length, _InboxTab.auto: state.auto.length},
                  onChanged: (tab) => setState(() => _tab = tab),
                ),
                const SizedBox(height: AppSpacing.space4),
                if (_tab == _InboxTab.pending) ...[
                  if (state.pending.isEmpty)
                    _InboxEmpty(text: texts.inboxEmpty)
                  else
                    for (final entry in state.pending)
                      _PendingCard(
                        entry: entry,
                        match: state.matches[entry.id],
                        onRecord: () => page._record(context, entry, state.matches[entry.id]),
                        onDismiss: () => inbox.add(CaptureInboxDismissed(entry.id)),
                        onMakePattern: () => page._makePattern(context, entry),
                      ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    texts.inboxRetention,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: colors.ink3),
                  ),
                ] else ...[
                  if (state.auto.isEmpty)
                    _InboxEmpty(text: texts.inboxAutoEmpty)
                  else
                    AppListCard(
                      children: [
                        for (final entry in state.auto)
                          _AutoRow(
                            entry: entry,
                            onReview: () => page._review(context, entry),
                            onUndo: () => page._undo(context, entry),
                          ),
                      ],
                    ),
                  if (state.linked.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space6),
                    AppSectionHeader(t.recurring.linkedTitle),
                    AppListCard(
                      children: [
                        for (final linked in state.linked)
                          AppListRow(
                            title: linked.ruleName,
                            subtitle: CycleMonthFormatter.formatDayMonth(linked.occurrenceDate),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AppMoneyText(linked.amount),
                                AppButton.text(
                                  small: true,
                                  label: t.recurring.unlinkAction,
                                  onPressed: () => inbox.add(CaptureInboxUnlinked(linked)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InboxEmpty extends StatelessWidget {
  const _InboxEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
      child: Column(
        children: [
          const AppIconTile(IconKey.taskAlt, tint: TileTint.green, size: 56),
          const SizedBox(height: AppSpacing.space4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appColors.ink2),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TransactionIcon(
                  kind: _transactionKind(entry.draft.kind),
                  categoryId: entry.draft.categoryId,
                  sourceIconId: entry.iconId,
                ),
                const SizedBox(width: AppSpacing.space2 + TransactionIcon.badgeOverhang),
                Expanded(
                  child: Text(
                    '${entry.appLabel} · ${CycleMonthFormatter.formatDateShort(entry.capturedAt)}',
                    style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                  ),
                ),
                PopupMenuButton<void>(
                  tooltip: texts.moreActions,
                  icon: AppIcon(IconKey.moreVert, color: colors.ink2),
                  itemBuilder: (_) => [PopupMenuItem<void>(onTap: onMakePattern, child: Text(texts.makePatternAction))],
                ),
              ],
            ),
            if (entry.possibleDuplicate || match != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space1,
                children: [
                  if (entry.possibleDuplicate) AppBadge(texts.possibleDuplicate, tone: AppTone.warning),
                  if (match case final m?)
                    AppBadge(
                      t.recurring.matchLabel(name: m.rule.note, date: CycleMonthFormatter.formatDayMonth(m.date)),
                      tone: AppTone.positive,
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.space3),
            if (amount == null)
              Text(texts.amountUnknown, style: textTheme.titleMedium?.copyWith(color: colors.warning))
            else
              AppMoneyText(amount, kind: _moneyKind(entry.draft.kind), size: MoneySize.large),
            if (note.isNotEmpty) Text(note, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.space1),
            Text(
              entry.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: colors.ink2),
            ),
            const SizedBox(height: AppSpacing.space3),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.text(small: true, label: texts.dismissAction, onPressed: onDismiss),
                const SizedBox(width: AppSpacing.space2),
                AppButton(small: true, label: texts.recordAction, onPressed: onRecord),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

TransactionKind _transactionKind(DraftKind kind) => switch (kind) {
  DraftKind.income => TransactionKind.income,
  DraftKind.expense => TransactionKind.expense,
  DraftKind.transfer => TransactionKind.transfer,
};

MoneyKind _moneyKind(DraftKind? kind) => switch (kind) {
  DraftKind.income => MoneyKind.income,
  DraftKind.expense => MoneyKind.expense,
  DraftKind.transfer => MoneyKind.transfer,
  null => MoneyKind.balance,
};

/// Satu transaksi yang tercatat otomatis: ketuk untuk meninjau, "Batalkan"
/// menghapusnya (dengan konfirmasi).
class _AutoRow extends StatelessWidget {
  const _AutoRow({required this.entry, required this.onReview, required this.onUndo});

  final AutoRecordedEntry entry;
  final VoidCallback onReview;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final amount = entry.amountSen;
    return AppListRow(
      onTap: onReview,
      leading: TransactionIcon(kind: _transactionKind(entry.kind), categoryId: entry.categoryId, sourceIconId: entry.iconId),
      title: entry.note.isEmpty ? entry.appLabel : entry.note,
      subtitle: '${entry.appLabel} · ${CycleMonthFormatter.formatDateShort(entry.transactionDate)}',
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppMoneyText(amount, kind: _moneyKind(entry.kind)),
          AppButton.text(small: true, label: texts.undoAction, onPressed: onUndo),
        ],
      ),
    );
  }
}
