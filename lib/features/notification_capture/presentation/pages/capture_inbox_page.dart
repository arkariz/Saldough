import 'dart:async';

import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_card_class.dart';
import 'package:saldough/features/notification_capture/domain/services/negative_shapes.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/capture_inbox_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/navigation/notification_capture_route_keys.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/access_disclosure.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/auto_offer.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/open_capture_record.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
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
  const CaptureInboxPage({super.key});

  /// Catat lewat CATAT. Bila draf cocok dengan satu kemunculan rutin,
  /// CATAT terisi kategori dan catatan dari rutin (yang kosong saja) dan
  /// transaksinya tertaut ke kemunculan itu (ADR-035 §3.4).
  Future<void> _record(
    BuildContext context,
    CaptureInboxEntry entry,
    OccurrenceMatch? match, {
    required String via,
    required String cardClass,
    String? budgetItemId,
  }) async {
    final bloc = context.read<CaptureInboxBloc>();
    final settings = context.read<NotificationSettingsBloc>();
    AppAnalytics.log(CaptureEvents.cardAction(action: via, cardClass: cardClass));
    RecordSavedInfo? savedInfo;
    final saved = await openCaptureRecord(
      context,
      entry,
      match,
      budgetItemId: budgetItemId,
      onSaved: (info) => savedInfo = info,
    );
    if (!saved) return;
    AppAnalytics.log(CaptureEvents.recordSaved(via: via, cardClass: cardClass));
    bloc.add(CaptureInboxRecorded(entry.id));
    // Belajar (E1/E2): kategori, dompet, dan pos yang baru atau diubah diingat.
    final undoCategory = await bloc.rememberCategory(
      entry,
      categoryId: savedInfo?.categoryId,
      note: savedInfo?.note ?? '',
    );
    final learnedWallet = await bloc.rememberWallet(entry, walletId: savedInfo?.walletId);
    final learnedBudget = await bloc.rememberBudgetItem(
      entry,
      budgetItemId: savedInfo?.budgetItemId,
      suggestedItemId: budgetItemId,
    );
    // Tawaran catat otomatis per bentuk (E3): hanya bila tidak ada jenis, dompet,
    // atau nominal yang diubah. Tampil sebagai banner, bukan snackbar.
    final savedKind = switch (savedInfo?.choice) {
      RecordChoice.expense => DraftKind.expense,
      RecordChoice.income => DraftKind.income,
      _ => null,
    };
    final offerTemplate = await bloc.autoOfferFor(
      entry,
      savedKind: savedKind,
      savedAmountSen: savedInfo?.amountSen,
      savedWalletId: savedInfo?.walletId,
    );
    if (offerTemplate != null) {
      bloc.add(CaptureInboxOfferRaised(AutoOfferPrompt(entry: entry, amountSen: savedInfo?.amountSen)));
    }
    if (!context.mounted) return;

    // Satu aksi, satu snackbar: semua yang diingat dalam satu ringkasan, satu Batalkan.
    final texts = t.notificationCapture;
    final lines = <String>[];
    final undos = <Future<void> Function()>[];
    if (undoCategory != null) {
      final categoryName =
          ActiveCategories.notifier.value.where((c) => c.id == savedInfo?.categoryId).firstOrNull?.name ?? '';
      lines.add(
        texts.rememberedCategoryLine(
          note: (savedInfo?.note ?? '').trim(),
          app: entry.appLabel,
          category: categoryName,
        ),
      );
      undos.add(undoCategory);
    }
    if (learnedBudget != null) {
      lines.add(texts.rememberedBudgetLine(name: learnedBudget.name));
      undos.add(learnedBudget.undo);
    }
    if (learnedWallet != null) {
      final walletName = settings.state.wallets.where((w) => w.id == savedInfo?.walletId).firstOrNull?.name ?? '';
      lines.add(texts.rememberedWalletLine(hint: learnedWallet.hint, wallet: walletName));
      undos.add(learnedWallet.undo);
    }
    if (lines.isEmpty) return;
    ScaffoldMessenger.of(context).showAppSnackBar(
      actionSnackBar(
        context,
        content: DsSnackMessage(title: texts.rememberedTitle, message: lines.join('\n')),
        action: SnackBarAction(
          key: const ValueKey('inbox-remembered-undo'),
          label: texts.rememberedUndoAll,
          onPressed: () => unawaited(Future.wait([for (final undo in undos) undo()])),
        ),
      ),
    );
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

/// Isi kotak masuk (prototipe `KotakMasuk.dc.html`, rupa design system v2):
/// segmen "Perlu dicek" / "Tercatat otomatis" dengan hitungan, kartu
/// tangkapan, dan daftar yang tercatat otomatis.
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
  }

  _InboxTab _tabFor(CaptureInboxState state) =>
      _picked ??= state.pending.isEmpty && state.auto.isNotEmpty ? _InboxTab.auto : _InboxTab.pending;

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final ds = context.ds;
    final page = widget.page;
    return Scaffold(
      appBar: AppBar(title: Text(texts.inboxTitle)),
      body: SafeArea(
        child: BlocBuilder<CaptureInboxBloc, CaptureInboxState>(
          builder: (context, state) {
            if (state.isLoading) return const _InboxSkeleton();
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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                const _AccessBanner(),
                DsSegmentedPill<_InboxTab>(
                  segments: [
                    DsSegment(value: _InboxTab.pending, label: texts.inboxPendingTitle, count: state.pending.length),
                    DsSegment(value: _InboxTab.auto, label: texts.inboxAutoTitle, count: state.auto.length),
                  ],
                  selected: tab,
                  onChanged: (tab) => setState(() => _picked = tab),
                ),
                // Pintu ke setelan sumber, juga saat kotak masuk kosong
                // (FEATURE_DISCOVERY P-8).
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: DsInlineAction(
                      key: const ValueKey('inbox-manage-sources'),
                      dense: true,
                      icon: Icons.tune_rounded,
                      label: t.discovery.notification.manageSources,
                      onPressed: () {
                        AppAnalytics.log(
                          DiscoveryEvents.notificationRowTapped(state: 'active', surface: 'inbox', action: 'manage'),
                        );
                        unawaited(context.pushRoute(NotificationCaptureRouteKeys.settings, const EmptyInput()));
                      },
                    ),
                  ),
                ),
                // Tawaran catat otomatis: tetap sampai dijawab, di tab mana pun.
                if (state.offer case final offer?)
                  AutoOfferBanner(
                    prompt: offer,
                    onYes: () => unawaited(answerAutoOfferYes(context, inbox, offer)),
                    onLater: () => inbox.add(const CaptureInboxOfferDismissed()),
                  ),
                if (tab == _InboxTab.pending) ...[
                  if (state.pending.isEmpty)
                    _InboxEmpty(asset: ClayIcons.done, text: texts.inboxEmpty)
                  else
                  // Catat semua yang cocok: Plus, bila ada dua kartu atau lebih yang boleh satu ketuk.
                  if (ActivePlan.isPlus && eligible.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DsButton.secondary(
                        key: const ValueKey('inbox-confirm-all'),
                        label: texts.confirmAllAction(n: eligible.length),
                        icon: Icons.done_all_rounded,
                        expand: true,
                        onPressed: () => inbox.add(
                          CaptureInboxConfirmed([for (final e in eligible) (e, state.matches[e.id])]),
                        ),
                      ),
                    ),
                  for (final entry in state.pending)
                    _PendingCard(
                      entry: entry,
                      match: state.matches[entry.id],
                      budgetItem: state.budgetSuggestions[entry.id],
                      existing: state.duplicates[entry.id],
                      oneTap: eligible.contains(entry),
                      onConfirm: () => inbox.add(CaptureInboxConfirmed([(entry, state.matches[entry.id])])),
                      onRecord: () => page._record(
                        context,
                        entry,
                        state.matches[entry.id],
                        budgetItemId: state.budgetSuggestions[entry.id]?.itemId,
                        via: eligible.contains(entry) ? 'edit_first' : 'record',
                        cardClass: captureClassName(state.cardClassFor(entry)),
                      ),
                      onDismiss: () => inbox.add(CaptureInboxDismissed(entry.id)),
                      onNotTransaction: () => inbox.add(CaptureInboxMarkedNotTransaction(entry.id)),
                      onLink: (existing, match) =>
                          inbox.add(CaptureInboxLinkedToExisting(id: entry.id, existing: existing, match: match)),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    texts.inboxRetention,
                    textAlign: TextAlign.center,
                    style: ds.typography.bodySm.copyWith(color: ds.colors.textMuted),
                  ),
                ] else ...[
                  if (state.auto.isEmpty)
                    _InboxEmpty(asset: ClayIcons.emptyTray, text: texts.inboxAutoEmpty)
                  else
                    DsListCard(
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
                    const SizedBox(height: 24),
                    DsSectionHeader(title: t.recurring.linkedTitle),
                    const SizedBox(height: 8),
                    DsListCard(
                      children: [
                        for (final linked in state.linked)
                          _InboxRow(
                            leading: const DsIconTile(icon: Icons.link_rounded),
                            title: linked.ruleName,
                            subtitle: CycleMonthFormatter.formatDayMonth(linked.occurrenceDate),
                            amount: AppMoneyText.format(linked.amount, MoneyKind.balance),
                            kind: DsLedgerKind.transfer,
                            action: DsInlineAction(
                              dense: true,
                              label: t.recurring.unlinkAction,
                              onPressed: () => inbox.add(CaptureInboxUnlinked(linked)),
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

/// Kerangka muat: segmen dan tiga kartu.
class _InboxSkeleton extends StatelessWidget {
  const _InboxSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsSkeleton(height: 42, radius: DsRadius.lgAll),
        SizedBox(height: 16),
        DsSkeleton(height: 132, radius: DsRadius.lgAll),
        SizedBox(height: 12),
        DsSkeleton(height: 132, radius: DsRadius.lgAll),
        SizedBox(height: 12),
        DsSkeleton(height: 132, radius: DsRadius.lgAll),
      ],
    ),
  );
}

/// Izin membaca notifikasi dicabut: tanpa banner ini kotak masuk tampak kosong
/// ("Tidak ada yang perlu dicek") padahal tidak ada notifikasi yang masuk.
class _AccessBanner extends StatelessWidget {
  const _AccessBanner();

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final ds = context.ds;
    return BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
      builder: (context, state) {
        if (state.isLoading || !state.settings.enabled || state.accessGranted) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: DsCard(
            key: const ValueKey('inbox-access-banner'),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DsIconTile.asset(asset: ClayIcons.warning, tone: DsIconTileTone.warning, size: DsIconTileSize.sm),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(texts.accessMissingTitle, style: ds.typography.titleMd),
                      const SizedBox(height: 4),
                      Text(
                        texts.accessMissingBody,
                        style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      DsButton.compact(
                        key: const ValueKey('inbox-access-grant'),
                        label: texts.accessAction,
                        onPressed: () async {
                          final bloc = context.read<NotificationSettingsBloc>();
                          if (await showAccessDisclosure(context)) await bloc.openAccessSettings();
                        },
                      ),
                    ],
                  ),
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
  const _InboxEmpty({required this.asset, required this.text});

  final String asset;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return DsCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          DsIconTile.asset(asset: asset, size: DsIconTileSize.lg),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Ikon kiri tangkapan, selaras dengan baris Riwayat: ikon clay kategori,
/// atau ikon asli aplikasi sumber bila ada.
class _EntryLeading extends StatelessWidget {
  const _EntryLeading({required this.kind, this.categoryId, this.sourceIconId, this.title});

  final DraftKind kind;
  final String? categoryId;
  final String? sourceIconId;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final txKind = _transactionKind(kind);
    final clay = sourceIconId == null
        ? ClayIcons.forIcon(TransactionIcon.iconKeyFor(kind: txKind, categoryId: categoryId, title: title))
        : null;
    if (clay != null) {
      return DsIconTile.asset(
        asset: clay,
        tone: txKind == TransactionKind.income ? DsIconTileTone.income : DsIconTileTone.neutral,
      );
    }
    return SizedBox.square(
      dimension: 40,
      child: Center(
        child: TransactionIcon(
          kind: txKind,
          categoryId: categoryId,
          sourceIconId: sourceIconId,
          title: title,
          ringColor: context.ds.colors.surfaceCard,
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.entry,
    required this.match,
    required this.budgetItem,
    required this.existing,
    required this.oneTap,
    required this.onConfirm,
    required this.onRecord,
    required this.onDismiss,
    required this.onNotTransaction,
    required this.onLink,
  });

  final CaptureInboxEntry entry;
  final OccurrenceMatch? match;

  /// Saran pos anggaran (E2); hanya label dan isian awal CATAT.
  final BudgetItemOption? budgetItem;

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

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final ds = context.ds;
    final c = ds.colors;
    final amount = entry.draft.amountSen;
    final note = entry.draft.note.trim();
    final isIncome = entry.draft.kind == DraftKind.income;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DsCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _EntryLeading(
                  kind: entry.draft.kind,
                  categoryId: entry.draft.categoryId,
                  sourceIconId: entry.iconId,
                  title: note,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.appLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ds.typography.titleMd.copyWith(fontSize: 14),
                      ),
                      Text(
                        CycleMonthFormatter.formatDateShort(entry.capturedAt),
                        style: ds.typography.bodySm.copyWith(fontSize: 12, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (entry.possibleDuplicate ||
                existing != null ||
                match != null ||
                budgetItem != null ||
                _reasonShown != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (entry.possibleDuplicate || existing != null)
                    DsBadge(label: texts.possibleDuplicate, tone: DsBadgeTone.warning),
                  // Kenapa perlu dicek (QA PR #43 F16).
                  if (_reasonShown case final reason?)
                    DsBadge(
                      key: const ValueKey('inbox-review-reason'),
                      label: _reasonLabel(reason),
                      tone: DsBadgeTone.neutral,
                    ),
                  if (match case final m?)
                    DsBadge(
                      label: t.recurring.matchLabel(
                        name: m.rule.note,
                        date: CycleMonthFormatter.formatDayMonth(m.date),
                      ),
                      tone: DsBadgeTone.income,
                    ),
                  if (budgetItem case final item?)
                    DsBadge(
                      key: const ValueKey('inbox-budget-suggestion'),
                      label: texts.budgetSuggestion(name: item.itemName, budget: item.budgetName),
                      tone: DsBadgeTone.neutral,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (amount == null)
              Text(texts.amountUnknown, style: ds.typography.titleMd.copyWith(color: c.warning))
            else
              Text(
                AppMoneyText.format(amount, _moneyKind(entry.draft.kind)),
                style: ds.typography.amount.copyWith(fontSize: 20, color: isIncome ? c.income : c.textPrimary),
              ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(note, style: ds.typography.titleMd.copyWith(fontSize: 14)),
            ],
            const SizedBox(height: 4),
            Text(
              entry.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ds.typography.bodySm.copyWith(fontSize: 12, color: c.textSecondary),
            ),
            if (existing case final tx?) ...[
              const SizedBox(height: 4),
              Text(
                key: const ValueKey('inbox-duplicate-of'),
                texts.duplicateOf(label: _existingLabel(tx)),
                style: ds.typography.bodySm.copyWith(fontSize: 12, color: c.warning),
              ),
            ],
            const SizedBox(height: 12),
            if (existing != null)
              _duplicateActions(existing!)
            else
              // Wrap, bukan Row: tiga tombol tidak muat sebaris di 360dp.
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  DsInlineAction(dense: true, label: texts.dismissAction, onPressed: onDismiss),
                  // Promosi dan pengumuman: pelajari supaya tidak muncul lagi. Hanya
                  // untuk kartu yang perlu diisi dan punya nominal terbaca (bentuknya
                  // bisa dipelajari dengan aman).
                  if (!oneTap && negativeTemplateFor(entry.text) != null)
                    DsInlineAction(
                      key: ValueKey('inbox-not-transaction-${entry.id}'),
                      dense: true,
                      label: texts.notTransactionAction,
                      onPressed: onNotTransaction,
                    ),
                  // Satu ketuk: Ubah dulu membuka CATAT, Catat langsung mencatat.
                  if (oneTap)
                    DsInlineAction(
                      key: ValueKey('inbox-edit-first-${entry.id}'),
                      dense: true,
                      label: texts.editFirstAction,
                      onPressed: onRecord,
                    ),
                  DsInlineAction(
                    key: ValueKey('inbox-confirm-${entry.id}'),
                    dense: true,
                    tone: DsInlineActionTone.primary,
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
      spacing: 8,
      runSpacing: 8,
      children: [
        DsInlineAction(
          key: const ValueKey('inbox-record-anyway'),
          dense: true,
          label: texts.recordAnywayAction,
          onPressed: onRecord,
        ),
        DsInlineAction(
          key: const ValueKey('inbox-close-duplicate'),
          dense: true,
          tone: canLink ? DsInlineActionTone.tonal : DsInlineActionTone.primary,
          label: texts.closeDuplicateAction,
          onPressed: onDismiss,
        ),
        if (canLink)
          DsInlineAction(
            key: const ValueKey('inbox-link-existing'),
            dense: true,
            tone: DsInlineActionTone.primary,
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
    CaptureReviewReason.amountUnclear => texts.amountUnclear,
    CaptureReviewReason.otherCurrency => texts.otherCurrency,
    CaptureReviewReason.kindUnclear => texts.kindUnclear,
    CaptureReviewReason.walletUnknown => texts.walletUnknown,
    CaptureReviewReason.categoryUnclear => texts.categoryUnclear,
    CaptureReviewReason.dateUnclear => texts.dateUnclear,
    CaptureReviewReason.amountUnusual => texts.amountUnusual,
  };
}

TransactionKind _transactionKind(DraftKind? kind) => switch (kind) {
  DraftKind.income => TransactionKind.income,
  DraftKind.transfer => TransactionKind.transfer,
  DraftKind.expense || null => TransactionKind.expense,
};

MoneyKind _moneyKind(DraftKind? kind) => switch (kind) {
  DraftKind.income => MoneyKind.income,
  DraftKind.expense => MoneyKind.expense,
  DraftKind.transfer => MoneyKind.transfer,
  null => MoneyKind.balance,
};

DsLedgerKind _ledgerKind(DraftKind? kind) => switch (kind) {
  DraftKind.income => DsLedgerKind.income,
  DraftKind.transfer => DsLedgerKind.transfer,
  DraftKind.expense || null => DsLedgerKind.expense,
};

/// Baris daftar di kartu daftar: [DsLedgerRow] dengan satu aksi di bawahnya,
/// rata kanan.
class _InboxRow extends StatelessWidget {
  const _InboxRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.kind,
    required this.action,
    this.badge,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final String amount;
  final DsLedgerKind kind;
  final Widget action;
  final Widget? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DsLedgerRow(
        leading: leading,
        title: title,
        subtitle: subtitle,
        amount: amount,
        badge: badge,
        kind: kind,
        onTap: onTap,
      ),
      Align(
        alignment: Alignment.centerRight,
        child: Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 10), child: action),
      ),
    ],
  );
}

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
    final kind = _moneyKind(entry.kind);
    return _InboxRow(
      onTap: onReview,
      leading: _EntryLeading(
        kind: entry.kind,
        categoryId: entry.categoryId,
        sourceIconId: entry.iconId,
        title: entry.note,
      ),
      title: entry.note.isEmpty ? entry.appLabel : entry.note,
      subtitle: '${entry.appLabel} · ${CycleMonthFormatter.formatDateShort(entry.transactionDate)}',
      amount: AppMoneyText.format(entry.amountSen, kind),
      kind: _ledgerKind(entry.kind),
      badge: entry.isNew
          ? DsBadge(key: const ValueKey('auto-new-badge'), label: texts.autoNewBadge, tone: DsBadgeTone.income)
          : null,
      action: DsInlineAction(dense: true, label: texts.undoAction, onPressed: onUndo),
    );
  }
}
