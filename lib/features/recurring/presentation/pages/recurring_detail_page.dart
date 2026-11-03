import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_state.dart';
import 'package:saldough/features/recurring/presentation/recurring_display.dart';
import 'package:saldough/features/recurring/presentation/widgets/reminder_nudge_card.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/category/category_presentation.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:state_management/state_management.dart';

enum _MenuAction { pause, end, delete }

/// Rincian rutin (PLAN_TAB_LAYOUT §6.5, RECURRING_AND_FORECAST §8.3):
/// kepala (nominal, jadwal, dompet, kategori, akhir, progres k/N), cara
/// bayar, kemunculan berikutnya dengan Lewati, dan riwayat tercatat.
/// Satu tombol primer **Ubah** (CATAT mode jadwal); Jeda, Akhiri, Hapus di
/// menu ⋮. Tidak ada yang di sini mengubah transaksi atau saldo.
class RecurringDetailPage extends StatelessWidget {
  /// Membuat [RecurringDetailPage].
  const RecurringDetailPage({required this.ruleId, this.rootContainer, super.key});

  /// Kontainer akar untuk catatan pengingat (Fase 21); `null` = tanpa.
  final GetIt? rootContainer;

  /// Rutin yang ditampilkan.
  final String ruleId;

  static const _nextCount = 3;
  static const _historyCount = 6;

  Future<void> _onMenu(BuildContext context, _MenuAction action, RecurringRule rule) async {
    final bloc = context.read<RecurringBloc>();
    switch (action) {
      case _MenuAction.pause:
        bloc.add(RecurringPauseToggled(rule.id));
      case _MenuAction.end:
        bloc.add(RecurringEnded(rule.id));
      case _MenuAction.delete:
        final navigator = Navigator.of(context);
        final confirmed = await showConfirmDelete(
          context,
          title: t.recurring.deleteTitle,
          message: t.recurring.deleteBody,
        );
        if (!confirmed) return;
        bloc.add(RecurringDeleted(rule.id));
        navigator.pop();
    }
  }

  /// Pemilih pos anggaran rutin untuk tautan (ADR-036 §3.4): hanya pos
  /// bertemplate berdompet sama; "Lepas tautan" bila sudah tertaut.
  Future<void> _pickBudgetItem(BuildContext context, RecurringRule rule, RecurringState state) async {
    final bloc = context.read<RecurringBloc>();
    final options = linkableBudgetItems(rule, state.budgetOptions);
    const unlink = '';
    final picked = await showOptionSheet<String>(
      context,
      title: t.recurring.budgetLinkPickerTitle,
      subtitle: options.isEmpty ? t.recurring.budgetLinkEmpty : null,
      current: rule.budgetItemKey,
      options: [
        for (final option in options)
          if (option.templateItemId case final id?)
            OptionSheetItem(
              value: id,
              label: t.recurring.budgetLinkValue(item: option.itemName, budget: option.budgetName),
            ),
        if (rule.budgetItemKey != null) OptionSheetItem(value: unlink, label: t.recurring.budgetLinkRemove),
      ],
    );
    if (picked == null || picked == rule.budgetItemKey) return;
    bloc.add(RecurringBudgetLinkChanged(ruleId: rule.id, key: picked == unlink ? null : picked));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecurringBloc, RecurringState>(
      builder: (context, state) {
        if (state.isLoading) return const Scaffold(body: AppSkeletonPage());
        final rule = state.ruleOf(ruleId);
        if (rule == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(t.recurring.notFound)),
          );
        }
        final ds = context.ds;
        final c = ds.colors;
        final bloc = context.read<RecurringBloc>();
        final today = state.today;
        final recorded = state.recordedFor(rule.id);
        final next = occurrenceStatusesOf(
          rule,
          from: today,
          until: DateTime(today.year + 5, today.month, today.day),
          today: today,
          transactions: state.transactions,
        ).where((o) => o.status != OccurrenceStatus.recorded).take(_nextCount).toList();
        final last = recorded.isEmpty ? null : recorded.first;
        final priceUp =
            last != null &&
            rule.amountMode == RecurringAmountMode.fixed &&
            isPriceIncrease(planned: rule.amount, recorded: last.amount);
        final end = rule.end;
        final wallet = rule.kind == RecurringKind.transfer
            ? '${state.walletName(rule.walletId) ?? '?'} → ${state.walletName(rule.toWalletId) ?? '?'}'
            : state.walletName(rule.walletId);
        final total = end is RecurringEndsAfter ? end.count : null;
        final done = total == null
            ? null
            : occurrencesOf(
                rule,
                from: rule.schedule.anchorDate,
                until: DateTime(today.year, today.month, today.day + 1),
              ).length;
        final category = ActiveCategories.byId(rule.categoryId);
        final icon = category != null
            ? categoryIcon(category, title: rule.note)
            : switch (rule.kind) {
                RecurringKind.income => IconKey.income,
                RecurringKind.expense => IconKey.expense,
                RecurringKind.transfer => IconKey.transfer,
              };
        final kindLabel = switch (rule.kind) {
          RecurringKind.income => t.record.kindIncome,
          RecurringKind.expense => t.record.kindExpense,
          RecurringKind.transfer => t.record.kindTransfer,
        };
        final kindColor = switch (rule.kind) {
          RecurringKind.income => c.income,
          RecurringKind.expense => c.textPrimary,
          RecurringKind.transfer => c.textSecondary,
        };
        final clay =
            ClayIcons.forIcon(icon) ??
            switch (rule.kind) {
              RecurringKind.income => ClayIcons.incomeArrow,
              RecurringKind.expense => ClayIcons.expenseArrow,
              RecurringKind.transfer => ClayIcons.transfer,
            };
        final lastDate = lastOccurrence(rule);
        return Scaffold(
          appBar: AppBar(
            title: Text(
              rule.note.isEmpty ? t.record.repeat.fallbackName : rule.note,
              style: ds.typography.headlineMd.copyWith(fontSize: 20),
            ),
            centerTitle: false,
            actions: [
              PopupMenuButton<_MenuAction>(
                tooltip: t.recurring.moreActions,
                icon: Icon(Icons.more_vert, color: c.textPrimary),
                onSelected: (action) => _onMenu(context, action, rule),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _MenuAction.pause,
                    child: Text(rule.isPaused ? t.recurring.resumeAction : t.recurring.pauseAction),
                  ),
                  if (lastDate == null || !lastDate.isBefore(today))
                    PopupMenuItem(value: _MenuAction.end, child: Text(t.recurring.endAction)),
                  PopupMenuItem(value: _MenuAction.delete, child: Text(t.recurring.deleteAction)),
                ],
              ),
            ],
          ),
          // Satu tombol primer menempel di bawah (prototipe `RincianRutin.dc.html`).
          bottomNavigationBar: DsStickyBar(
            child: DsButton(
              expand: true,
              icon: Icons.edit_outlined,
              label: t.recurring.editAction,
              onPressed: () => context.pushRoute(RecordRouteKeys.sheet, RecordSheetInput(editRule: rule)),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                DsReveal(
                  child: DecoratedBox(
                    decoration: ds.elevation.card.decoration().copyWith(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [c.actionPrimary.withValues(alpha: 0.10), c.surfaceCard],
                        stops: const [0, 0.55],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              DsIdleMotion(
                                kind: DsIdleKind.float,
                                child: DsIconTile.asset(asset: clay, size: DsIconTileSize.lg),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      [kindLabel, ?category?.name].join(' · '),
                                      style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                                    ),
                                    // Nominal kira-kira memakai tanda ≈ dari `signedAmount`.
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: AlignmentDirectional.centerStart,
                                      child: DsCountUp(
                                        value: rule.amount,
                                        builder: (context, current) => Text(
                                          signedAmount(
                                            rule.kind,
                                            current,
                                            approximate: rule.amountMode == RecurringAmountMode.estimated,
                                          ),
                                          style: ds.typography.numericalDisplay.copyWith(color: kindColor),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: c.outlineSubtle),
                          const SizedBox(height: 8),
                          _InfoRow(label: t.recurring.detailSchedule, value: scheduleText(rule)),
                          if (wallet != null) _InfoRow(label: t.recurring.detailWallet, value: wallet),
                          if (lastDate != null)
                            _InfoRow(
                              label: t.recurring.detailEnds,
                              value: [
                                if (total != null) t.recurring.countLine(n: total),
                                CycleMonthFormatter.formatDateShort(lastDate),
                              ].join(', '),
                            ),
                          if (rule.kind != RecurringKind.income)
                            _InfoRow(
                              label: t.recurring.detailPayment,
                              value: rule.effectivePaymentMode == RecurringPaymentMode.autoDebit
                                  ? t.recurring.autoDebitLine
                                  : t.recurring.reminderLine(n: rule.remindDaysBefore),
                            ),
                          if (rule.isPaused) _InfoRow(label: t.recurring.detailStatus, value: t.recurring.pausedLine),
                          if (total != null && done != null) ...[
                            const SizedBox(height: 8),
                            _InstallmentProgress(done: done, total: total),
                            const SizedBox(height: 4),
                            Text(
                              t.recurring.progressLine(k: done, n: total),
                              style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                            ),
                          ],
                          // W7 bebas cicilan (ADR-036 §3.7).
                          if (installmentFreeOf(rule, today: today) case final free?) ...[
                            const SizedBox(height: 12),
                            DecoratedBox(
                              decoration: BoxDecoration(color: c.incomeContainer, borderRadius: DsRadius.mdAll),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    SvgPicture.asset(ClayIcons.done, width: 24, height: 24),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        t.recurring.installmentFreeLine(
                                          month: CycleMonthFormatter.formatMonthYearShort(free.from),
                                          amount: AppMoneyFormatter.format(free.perMonth),
                                        ),
                                        key: const ValueKey('recurring-installment-free'),
                                        style: ds.typography.bodySm.copyWith(color: c.onIncomeContainer),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (priceUp) ...[
                  const SizedBox(height: 16),
                  DsReveal(
                    index: 1,
                    child: DsCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DsIconTile.asset(
                                asset: ClayIcons.warning,
                                tone: DsIconTileTone.warning,
                                size: DsIconTileSize.sm,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t.recurring.priceUp(
                                    amount: AppMoneyFormatter.format(last.amount),
                                    usual: AppMoneyFormatter.format(rule.amount),
                                  ),
                                  style: ds.typography.bodyMd,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          DsInlineActions(
                            actions: [
                              DsInlineAction(
                                tone: DsInlineActionTone.primary,
                                label: t.recurring.priceUpdateAction(amount: AppMoneyFormatter.format(last.amount)),
                                onPressed: () => bloc.add(RecurringAmountUpdated(ruleId: rule.id, amount: last.amount)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                DsSectionHeader(title: t.recurring.settingsTitle),
                const SizedBox(height: 8),
                DsListCard(
                  children: [
                    MergeSemantics(
                      child: DsSettingRow(
                        leading: DsIconTile.asset(asset: ClayIcons.bell, size: DsIconTileSize.sm),
                        title: t.recurring.ruleRemindersLabel,
                        trailing: Switch(
                          value: rule.reminders,
                          onChanged: (value) => bloc.add(RecurringRemindersToggled(ruleId: rule.id, enabled: value)),
                        ),
                      ),
                    ),
                    // Sakelar per rutin menyala tetapi pengingat global belum
                    // efektif: satu kalimat dan Nyalakan / Izinkan.
                    if (rule.reminders && rootContainer != null) ReminderRuleNote(container: rootContainer!),
                    if (rule.amountMode == RecurringAmountMode.fixed)
                      MergeSemantics(
                        child: DsSettingRow(
                          leading: DsIconTile.asset(asset: ClayIcons.repeat, size: DsIconTileSize.sm),
                          title: t.record.repeat.autoRecordLabel,
                          subtitle: t.record.repeat.autoRecordHint,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const PlusBadge(),
                              Switch(
                                key: const ValueKey('recurring-auto-record'),
                                value: rule.autoRecord,
                                // Otomasi R3 hanya untuk Plus (ADR-041 §3.8).
                                onChanged: (value) => ActivePlan.isPlus
                                    ? bloc.add(RecurringAutoRecordToggled(ruleId: rule.id, enabled: value))
                                    : unawaited(
                                        context.pushRoute(
                                          PremiumRouteKeys.paywall,
                                          const PaywallInput(PaywallTrigger.recurringAutomation),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (rule.kind == RecurringKind.expense)
                      DsSettingRow(
                        key: const ValueKey('recurring-budget-link'),
                        leading: DsIconTile.asset(asset: ClayIcons.piggy, size: DsIconTileSize.sm),
                        title: t.recurring.budgetLinkLabel,
                        subtitle: switch (linkedBudgetItem(rule, state.budgetOptions)) {
                          final item? => t.recurring.budgetLinkValue(item: item.itemName, budget: item.budgetName),
                          null => t.recurring.budgetLinkNone,
                        },
                        onTap: () => unawaited(_pickBudgetItem(context, rule, state)),
                      ),
                  ],
                ),
                if (next.isNotEmpty && !rule.isPaused) ...[
                  const SizedBox(height: 24),
                  DsSectionHeader(title: t.recurring.nextTitle),
                  const SizedBox(height: 8),
                  DsReveal(
                    child: DsCard(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        children: [
                          for (final (i, o) in next.indexed)
                            _NextLine(
                              date: o.date,
                              today: today,
                              amount: rule.amount,
                              kind: rule.kind,
                              approximate: rule.amountMode == RecurringAmountMode.estimated,
                              first: i == 0,
                              last: i == next.length - 1,
                              skipped: o.status == OccurrenceStatus.skipped,
                              onRecordEarly: () => rule.amountMode == RecurringAmountMode.fixed
                                  ? bloc.add(RecurringOccurrenceRecorded(ruleId: rule.id, date: o.date))
                                  : unawaited(
                                      context.pushRoute(
                                        RecordRouteKeys.sheet,
                                        RecordSheetInput(occurrenceRule: rule, occurrenceDate: o.date),
                                      ),
                                    ),
                              onToggleSkip: () => o.status == OccurrenceStatus.skipped
                                  ? bloc.add(RecurringOccurrenceUnskipped(ruleId: rule.id, date: o.date))
                                  : bloc.add(RecurringOccurrenceSkipped(ruleId: rule.id, date: o.date)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                DsSectionHeader(title: t.recurring.recordedTitle),
                const SizedBox(height: 8),
                if (recorded.isEmpty)
                  DsReveal(
                    child: DsCard(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      child: Column(
                        children: [
                          const DsEmptyHero(asset: ClayIcons.receipt, orbit: [ClayIcons.clock], size: 96),
                          const SizedBox(height: 4),
                          Text(
                            t.recurring.noRecorded,
                            textAlign: TextAlign.center,
                            style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  DsListCard(
                    children: [
                      for (final (i, transaction) in recorded.take(_historyCount).indexed)
                        DsReveal(
                          index: i,
                          child: _OccurrenceLine(
                            date: transaction.recurrence!.occurrenceDate,
                            today: today,
                            title: occurrenceDateText(transaction.recurrence!.occurrenceDate, today),
                            amount: transaction.amount,
                            kind: rule.kind,
                            muted: true,
                            onTap: () =>
                                context.pushRoute(TransactionRouteKeys.detail, TransactionDetailInput(transaction)),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Baris label–nilai di kartu kepala.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Progres cicilan sebagai meter tersegmen: satu segmen per kemunculan
/// (hingga 24), yang tercatat menyala berurutan; lebih banyak dari itu
/// memakai meter 10 segmen.
class _InstallmentProgress extends StatelessWidget {
  const _InstallmentProgress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final perOccurrence = total <= 24;
    // Setengah langkah di atas supaya pembulatan ke bawah tidak kehilangan
    // satu segmen; nol tetap nol.
    final value = done <= 0 ? 0.0 : (perOccurrence ? (done + 0.5) / total : done / total).clamp(0.0, 1.0);
    return DsSegmentMeter(
      value: value,
      segments: perOccurrence ? total : 10,
      semanticLabel: t.recurring.progressLine(k: done, n: total),
    );
  }
}

/// Satu kemunculan di garis waktu **Berikutnya**: titik di rel (yang pertama
/// menyala dan berdenyut), tanggal + lencana jatuh tempo + nominal, lalu aksi
/// rapat di bawahnya. Yang dilewati dicoret dengan Batal lewati.
class _NextLine extends StatelessWidget {
  const _NextLine({
    required this.date,
    required this.today,
    required this.amount,
    required this.kind,
    required this.approximate,
    required this.first,
    required this.last,
    required this.skipped,
    required this.onRecordEarly,
    required this.onToggleSkip,
  });

  final DateTime date;
  final DateTime today;
  final int amount;
  final RecurringKind kind;
  final bool approximate;
  final bool first;
  final bool last;
  final bool skipped;
  final VoidCallback onRecordEarly;
  final VoidCallback onToggleSkip;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final lit = first && !skipped;
    final amountColor = skipped
        ? c.textMuted
        : switch (kind) {
            RecurringKind.income => c.income,
            RecurringKind.expense => c.textPrimary,
            RecurringKind.transfer => c.textSecondary,
          };
    final dot = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit ? c.actionPrimary : c.surfaceCard,
        border: Border.all(color: lit ? c.actionPrimary : c.outline, width: 2),
      ),
      child: const SizedBox.square(dimension: 12),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 4),
                if (lit) DsPulse(borderRadius: DsRadius.fullAll, child: dot) else dot,
                if (!last)
                  Expanded(
                    child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: c.outlineSubtle),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              occurrenceDateText(date, today),
                              overflow: TextOverflow.ellipsis,
                              style: ds.typography.titleMd.copyWith(
                                color: skipped ? c.textMuted : c.textPrimary,
                                decoration: skipped ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DsBadge(label: dueText(date, today), tone: lit ? DsBadgeTone.warm : DsBadgeTone.neutral),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            signedAmount(kind, amount, approximate: approximate),
                            style: ds.typography.amount.copyWith(color: amountColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (skipped)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(
                        width: 150,
                        child: DsInlineAction(label: t.recurring.unskipAction, onPressed: onToggleSkip),
                      ),
                    )
                  else
                    DsInlineActions(
                      actions: [
                        DsInlineAction(label: t.recurring.skipAction, onPressed: onToggleSkip),
                        DsInlineAction(
                          tone: DsInlineActionTone.primary,
                          label: t.recurring.recordEarlyAction,
                          onPressed: onRecordEarly,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris riwayat tercatat: kotak tanggal, judul, nominal bertanda, dan panah.
/// Diredupkan karena sudah selesai.
class _OccurrenceLine extends StatelessWidget {
  const _OccurrenceLine({
    required this.date,
    required this.today,
    required this.title,
    required this.amount,
    required this.kind,
    this.muted = false,
    this.onTap,
  });

  final DateTime date;
  final DateTime today;
  final String title;
  final int amount;
  final RecurringKind kind;
  final bool muted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final dim = muted;
    final amountColor = dim
        ? c.textMuted
        : switch (kind) {
            RecurringKind.income => c.income,
            RecurringKind.expense => c.textPrimary,
            RecurringKind.transfer => c.textSecondary,
          };
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.mdAll),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${date.day}',
                        style: ds.typography.amount.copyWith(
                          fontSize: 17,
                          height: 20 / 17,
                          color: dim ? c.textMuted : c.textPrimary,
                        ),
                      ),
                      Text(
                        CycleMonthFormatter.formatMonthShort(date),
                        style: ds.typography.bodySm.copyWith(fontSize: 11, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: ds.typography.titleMd.copyWith(
                  color: dim ? c.textMuted : c.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Nominal mengecil di layar sempit supaya aksi tetap utuh.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(signedAmount(kind, amount), style: ds.typography.amount.copyWith(color: amountColor)),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: c.textMuted),
            ],
          ],
        ),
      ),
    );
    return onTap == null
        ? row
        : DsPressable(semanticLabel: title, onPressed: onTap, pressedScale: 0.99, builder: (context, _) => row);
  }
}
