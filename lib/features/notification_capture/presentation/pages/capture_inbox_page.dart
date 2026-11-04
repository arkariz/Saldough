import 'dart:async';

import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_card_class.dart';
import 'package:saldough/features/notification_capture/domain/services/negative_shapes.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/capture_inbox_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/navigation/notification_capture_route_keys.dart';
import 'package:saldough/features/notification_capture/presentation/pages/notification_pattern_page.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/access_disclosure.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/open_capture_record.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:state_management/state_management.dart';

/// Kotak masuk Catat dari notifikasi (ADR-032 §3.6): tangkapan yang perlu
/// ditinjau (Catat membuka CATAT terisi; item hilang hanya bila tersimpan)
/// dan transaksi yang tercatat otomatis (Tinjau/Batalkan).
class CaptureInboxPage extends StatelessWidget {
  /// Membuat [CaptureInboxPage].
  const CaptureInboxPage({this.teachEntryId, super.key});

  /// Tangkapan yang pembuat polanya langsung dibuka begitu daftar termuat
  /// (Ajari pola dari kartu Beranda, FEATURE_DISCOVERY P-8); `null` = tidak.
  final String? teachEntryId;

  /// Catat lewat CATAT. Bila draf cocok dengan satu kemunculan rutin,
  /// CATAT terisi kategori dan catatan dari rutin (yang kosong saja) dan
  /// transaksinya tertaut ke kemunculan itu (ADR-035 §3.4).
  Future<void> _record(
    BuildContext context,
    CaptureInboxEntry entry,
    OccurrenceMatch? match, {
    required String via,
    required String cardClass,
  }) async {
    final bloc = context.read<CaptureInboxBloc>();
    AppAnalytics.log(CaptureEvents.cardAction(action: via, cardClass: cardClass));
    String? savedCategory;
    var savedNote = '';
    final saved = await openCaptureRecord(
      context,
      entry,
      match,
      onSaved: (categoryId, note) {
        savedCategory = categoryId;
        savedNote = note;
      },
    );
    if (!saved) return;
    AppAnalytics.log(CaptureEvents.recordSaved(via: via, cardClass: cardClass));
    bloc.add(CaptureInboxRecorded(entry.id));
    // Belajar (E1): kategori baru atau yang diubah diingat untuk pedagang ini, dengan Batalkan.
    final undo = await bloc.rememberCategory(entry, categoryId: savedCategory, note: savedNote);
    if (undo == null || !context.mounted) return;
    final categoryName = ActiveCategories.notifier.value.where((c) => c.id == savedCategory).firstOrNull?.name ?? '';
    final texts = t.notificationCapture;
    ScaffoldMessenger.of(context).showSnackBar(
      actionSnackBar(
        context,
        content: Text(texts.rememberedSnack(note: savedNote.trim(), app: entry.appLabel, category: categoryName)),
        action: SnackBarAction(label: texts.rememberedUndo, onPressed: () => unawaited(undo())),
      ),
    );
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
  Widget build(BuildContext context) => _InboxBody(page: this);
}

enum _InboxTab { pending, auto }

/// Isi kotak masuk (prototipe `KotakMasuk.dc.html`): segmen "Perlu dicek" /
/// "Tercatat otomatis" dengan hitungan, kartu tangkapan, dan daftar yang
/// tercatat otomatis.
class _InboxBody extends StatefulWidget {
  const _InboxBody({required this.page});

  final CaptureInboxPage page;

  @override
  State<_InboxBody> createState() => _InboxBodyState();
}

class _InboxBodyState extends State<_InboxBody> with WidgetsBindingObserver {
  /// `null` sampai isi pertama termuat: dibuka di segmen yang berisi item
  /// (Perlu dicek bila ada yang menunggu, kalau tidak Otomatis; QA PR #43
  /// F17), sesudah itu pilihan pengguna.
  _InboxTab? _picked;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Kembali dari setelan akses sistem: cek ulang izinnya.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationSettingsBloc>().add(const NotificationSettingsResumed());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.page.teachEntryId case final id?) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_teach(id)));
    }
  }

  /// Membuka pembuat pola untuk [entryId] begitu daftar termuat.
  Future<void> _teach(String entryId) async {
    final inbox = context.read<CaptureInboxBloc>();
    final loaded = inbox.state.isLoading ? await inbox.stream.firstWhere((s) => !s.isLoading) : inbox.state;
    if (!mounted) return;
    final entry = loaded.pending.where((e) => e.id == entryId).firstOrNull;
    if (entry != null) await widget.page._makePattern(context, entry);
  }

  _InboxTab _tabFor(CaptureInboxState state) =>
      _picked ??= state.pending.isEmpty && state.auto.isNotEmpty ? _InboxTab.auto : _InboxTab.pending;

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    final page = widget.page;
    return Scaffold(
      appBar: AppBar(
        title: Text(texts.inboxTitle),
      ),
      body: SafeArea(
        child: BlocBuilder<CaptureInboxBloc, CaptureInboxState>(
          builder: (context, state) {
            if (state.isLoading) return const AppSkeletonPage();
            final inbox = context.read<CaptureInboxBloc>();
            final tab = _tabFor(state);
            // Kartu yang boleh dicatat satu ketuk (ADR-044 §3.6): dikenali atau
            // cocok rencana, bukan duplikat; hanya Plus.
            final eligible = [
              for (final e in state.pending)
                if (oneTapAllowed(
                  cardClass: state.cardClassFor(e),
                  isPlus: ActivePlan.isPlus,
                ))
                  e,
            ];
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.space4, 0, AppSpacing.space4, AppSpacing.space8),
              children: [
                const _AccessBanner(),
                AppSegmentedControl<_InboxTab>(
                  options: [(_InboxTab.pending, texts.inboxPendingTitle), (_InboxTab.auto, texts.inboxAutoTitle)],
                  selected: tab,
                  counts: {_InboxTab.pending: state.pending.length, _InboxTab.auto: state.auto.length},
                  onChanged: (tab) => setState(() => _picked = tab),
                ),
                // Pintu ke setelan sumber dan pola, juga saat kotak masuk
                // kosong (FEATURE_DISCOVERY P-8).
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton.text(
                    key: const ValueKey('inbox-manage-sources'),
                    small: true,
                    label: t.discovery.notification.manageSources,
                    onPressed: () {
                      AppAnalytics.log(
                        DiscoveryEvents.notificationRowTapped(state: 'active', surface: 'inbox', action: 'manage'),
                      );
                      unawaited(context.pushRoute(NotificationCaptureRouteKeys.settings, const EmptyInput()));
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                if (tab == _InboxTab.pending) ...[
                  if (state.pending.isEmpty)
                    _InboxEmpty(text: texts.inboxEmpty)
                  else ...[
                    // Catat semua yang cocok: Plus, bila ada dua kartu atau lebih yang boleh satu ketuk.
                    if (ActivePlan.isPlus && eligible.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                        child: AppButton.secondary(
                          key: const ValueKey('inbox-confirm-all'),
                          label: texts.confirmAllAction(n: eligible.length),
                          expand: true,
                          onPressed: () => inbox.add(
                            CaptureInboxConfirmed([for (final e in eligible) (e, state.matches[e.id])]),
                          ),
                        ),
                      ),
                  ],
                  for (final entry in state.pending)
                    _PendingCard(
                      entry: entry,
                      match: state.matches[entry.id],
                      existing: state.duplicates[entry.id],
                      oneTap: eligible.contains(entry),
                      onConfirm: () => inbox.add(CaptureInboxConfirmed([(entry, state.matches[entry.id])])),
                      onRecord: () => page._record(
                        context,
                        entry,
                        state.matches[entry.id],
                        via: eligible.contains(entry) ? 'edit_first' : 'record',
                        cardClass: captureClassName(state.cardClassFor(entry)),
                      ),
                      onDismiss: () => inbox.add(CaptureInboxDismissed(entry.id)),
                      onNotTransaction: () => inbox.add(CaptureInboxMarkedNotTransaction(entry.id)),
                      onMakePattern: () => page._makePattern(context, entry),
                      onLink: (existing, match) =>
                          inbox.add(CaptureInboxLinkedToExisting(id: entry.id, existing: existing, match: match)),
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

/// Izin membaca notifikasi dicabut: tanpa banner ini kotak masuk tampak kosong
/// ("Tidak ada yang perlu dicek") padahal tidak ada notifikasi yang masuk.
class _AccessBanner extends StatelessWidget {
  const _AccessBanner();

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
      builder: (context, state) {
        if (state.isLoading || !state.settings.enabled || state.accessGranted) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space2, bottom: AppSpacing.space3),
          child: AppCard(
            key: const ValueKey('inbox-access-banner'),
            color: colors.warningSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(texts.accessMissingTitle, style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.space1),
                Text(texts.accessMissingBody, style: textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.space2),
                AppButton(
                  key: const ValueKey('inbox-access-grant'),
                  small: true,
                  label: texts.accessAction,
                  onPressed: () async {
                    final bloc = context.read<NotificationSettingsBloc>();
                    if (await showAccessDisclosure(context)) await bloc.openAccessSettings();
                  },
                ),
              ],
            ),
          ),
        );
      },
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
    required this.existing,
    required this.oneTap,
    required this.onConfirm,
    required this.onRecord,
    required this.onDismiss,
    required this.onNotTransaction,
    required this.onMakePattern,
    required this.onLink,
  });

  final CaptureInboxEntry entry;
  final OccurrenceMatch? match;

  /// Transaksi di buku besar yang tampak sama dengan kartu ini (ADR-044 §3.3).
  final Transaction? existing;
  final void Function(Transaction existing, OccurrenceMatch match) onLink;

  /// Boleh dicatat satu ketuk (ADR-044 §3.6).
  final bool oneTap;

  /// Catat satu ketuk tanpa formulir.
  final VoidCallback onConfirm;
  final VoidCallback onRecord;
  final VoidCallback onDismiss;

  /// "Bukan transaksi": tutup dan pelajari bentuknya (E1).
  final VoidCallback onNotTransaction;
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
            if (entry.possibleDuplicate || existing != null || match != null || _reasonShown != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space1,
                children: [
                  if (entry.possibleDuplicate || existing != null)
                    AppBadge(texts.possibleDuplicate, tone: AppTone.warning),
                  // Kenapa perlu dicek (QA PR #43 F16).
                  if (_reasonShown case final reason?)
                    AppBadge(
                      key: const ValueKey('inbox-review-reason'),
                      _reasonLabel(reason),
                      tone: AppTone.info,
                    ),
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
            if (existing case final tx?) ...[
              const SizedBox(height: AppSpacing.space1),
              Text(
                key: const ValueKey('inbox-duplicate-of'),
                texts.duplicateOf(label: _existingLabel(tx)),
                style: textTheme.bodySmall?.copyWith(color: colors.warning),
              ),
            ],
            const SizedBox(height: AppSpacing.space3),
            if (existing != null)
              _duplicateActions(existing!)
            else
              // Wrap, bukan Row: tiga tombol (Abaikan, Ajari pola, Catat) tidak
              // muat sebaris di 360dp.
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space1,
                children: [
                  AppButton.text(small: true, label: texts.dismissAction, onPressed: onDismiss),
                  // Promosi dan pengumuman: pelajari supaya tidak muncul lagi. Hanya
                  // untuk kartu yang perlu diisi dan punya nominal terbaca (bentuknya
                  // bisa dipelajari dengan aman).
                  if (!oneTap && negativeTemplateFor(entry.text) != null)
                    AppButton.text(
                      key: ValueKey('inbox-not-transaction-${entry.id}'),
                      small: true,
                      label: texts.notTransactionAction,
                      onPressed: onNotTransaction,
                    ),
                  // Satu ketuk: Ubah dulu membuka CATAT, Catat langsung mencatat.
                  if (oneTap)
                    AppButton.text(
                      key: ValueKey('inbox-edit-first-${entry.id}'),
                      small: true,
                      label: texts.editFirstAction,
                      onPressed: onRecord,
                    ),
                  // Nominal tak terbaca: ajari pola di sebelah tombol catat.
                  if (amount == null)
                    AppButton.secondary(
                      key: ValueKey('inbox-teach-${entry.id}'),
                      small: true,
                      label: t.discovery.notification.teachPattern,
                      onPressed: () {
                        AppAnalytics.log(
                          DiscoveryEvents.notificationRowTapped(
                            state: 'active',
                            surface: 'inbox',
                            action: 'teach_pattern',
                          ),
                        );
                        onMakePattern();
                      },
                    ),
                  AppButton(
                    key: ValueKey('inbox-confirm-${entry.id}'),
                    small: true,
                    label: texts.recordAction,
                    onPressed: oneTap ? onConfirm : onRecord,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Alasan perlu dicek yang layak ditampilkan: "Catat otomatis mati" adalah
  /// setelan, bukan alasan tangkapan ini, jadi tidak ditempel di tiap kartu.
  CaptureReviewReason? get _reasonShown =>
      entry.reviewReason == CaptureReviewReason.autoRecordOff ? null : entry.reviewReason;

  /// Catatan yang sama sudah ada (ADR-044 §3.3): menautkannya ke rutin yang
  /// cocok bila belum tertaut, menutup kartu, atau tetap mencatat bila
  /// ternyata pembelian kedua. Kartu tidak pernah ditutup otomatis.
  Widget _duplicateActions(Transaction tx) {
    final texts = t.notificationCapture;
    final rule = match;
    final canLink = tx.recurrence == null && rule != null;
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space1,
      children: [
        AppButton.text(
          key: const ValueKey('inbox-record-anyway'),
          small: true,
          label: texts.recordAnywayAction,
          onPressed: onRecord,
        ),
        if (canLink)
          AppButton.secondary(
            key: const ValueKey('inbox-close-duplicate'),
            small: true,
            label: texts.closeDuplicateAction,
            onPressed: onDismiss,
          )
        else
          AppButton(
            key: const ValueKey('inbox-close-duplicate'),
            small: true,
            label: texts.closeDuplicateAction,
            onPressed: onDismiss,
          ),
        if (canLink)
          AppButton(
            key: const ValueKey('inbox-link-existing'),
            small: true,
            label: texts.linkToRuleAction(name: rule.rule.note),
            onPressed: () => onLink(tx, rule),
          ),
      ],
    );
  }
}

String _existingLabel(Transaction tx) =>
    tx.note.trim().isEmpty ? CycleMonthFormatter.formatDateShort(tx.date) : tx.note.trim();

String _reasonLabel(CaptureReviewReason reason) {
  final texts = t.notificationCapture.reviewReason;
  return switch (reason) {
    CaptureReviewReason.autoRecordOff => texts.autoRecordOff,
    CaptureReviewReason.newPattern => texts.newPattern,
    CaptureReviewReason.amountUnclear => texts.amountUnclear,
    CaptureReviewReason.otherCurrency => texts.otherCurrency,
    CaptureReviewReason.kindUnclear => texts.kindUnclear,
    CaptureReviewReason.walletUnknown => texts.walletUnknown,
    CaptureReviewReason.categoryUnclear => texts.categoryUnclear,
    CaptureReviewReason.dateUnclear => texts.dateUnclear,
    CaptureReviewReason.recurringUnclear => texts.recurringUnclear,
  };
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
      leading: TransactionIcon(
        kind: _transactionKind(entry.kind),
        categoryId: entry.categoryId,
        sourceIconId: entry.iconId,
      ),
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
