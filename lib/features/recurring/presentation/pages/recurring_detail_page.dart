import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_state.dart';
import 'package:saldough/features/recurring/presentation/recurring_display.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/shared/category/category.dart';
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
  const RecurringDetailPage({required this.ruleId, super.key});

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
    final picked = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(t.recurring.budgetLinkPickerTitle),
        children: [
          if (options.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Text(t.recurring.budgetLinkEmpty),
            ),
          for (final option in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(option.templateItemId),
              child: Row(
                children: [
                  Expanded(
                    child: Text(t.recurring.budgetLinkValue(item: option.itemName, budget: option.budgetName)),
                  ),
                  if (option.templateItemId == rule.budgetItemKey) const AppIcon(IconKey.check),
                ],
              ),
            ),
          if (rule.budgetItemKey != null)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(unlink),
              child: Text(t.recurring.budgetLinkRemove),
            ),
        ],
      ),
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
        final colors = context.appColors;
        final textTheme = Theme.of(context).textTheme;
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
        final category = ActiveCategories.byId(rule.categoryId)?.name;
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
        return Scaffold(
          appBar: AppBar(
            title: Text(rule.note.isEmpty ? t.record.repeat.fallbackName : rule.note),
            actions: [
              PopupMenuButton<_MenuAction>(
                tooltip: t.recurring.moreActions,
                onSelected: (action) => _onMenu(context, action, rule),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _MenuAction.pause,
                    child: Text(rule.isPaused ? t.recurring.resumeAction : t.recurring.pauseAction),
                  ),
                  if (lastOccurrence(rule) == null || !lastOccurrence(rule)!.isBefore(today))
                    PopupMenuItem(value: _MenuAction.end, child: Text(t.recurring.endAction)),
                  PopupMenuItem(value: _MenuAction.delete, child: Text(t.recurring.deleteAction)),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                AppHardCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        signedAmount(
                          rule.kind,
                          rule.amount,
                          approximate: rule.amountMode == RecurringAmountMode.estimated,
                        ),
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        [scheduleText(rule), ?wallet, ?category].join(' · '),
                        style: textTheme.bodyMedium,
                      ),
                      if (rule.isPaused) Text(t.recurring.pausedLine, style: textTheme.bodySmall),
                      if (rule.kind != RecurringKind.income)
                        Text(
                          rule.effectivePaymentMode == RecurringPaymentMode.autoDebit
                              ? t.recurring.autoDebitLine
                              : t.recurring.reminderLine(n: rule.remindDaysBefore),
                          style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                        ),
                      if (lastOccurrence(rule) case final lastDate?)
                        Text(
                          [
                            if (total != null) t.recurring.countLine(n: total),
                            t.recurring.endsOnLine(date: CycleMonthFormatter.formatDateShort(lastDate)),
                          ].join(', '),
                          style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                        ),
                      if (total != null && done != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppSegmentedProgressBar(value: (done / total).clamp(0, 1).toDouble()),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          t.recurring.progressLine(k: done, n: total),
                          style: textTheme.bodySmall,
                        ),
                      ],
                      // W7 bebas cicilan (ADR-036 §3.7).
                      if (installmentFreeOf(rule, today: today) case final free?)
                        Text(
                          t.recurring.installmentFreeLine(
                            month: CycleMonthFormatter.formatMonthYearShort(free.from),
                            amount: AppMoneyFormatter.format(free.perMonth),
                          ),
                          key: const ValueKey('recurring-installment-free'),
                          style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.recurring.ruleRemindersLabel),
                  value: rule.reminders,
                  onChanged: (value) => bloc.add(RecurringRemindersToggled(ruleId: rule.id, enabled: value)),
                ),
                if (rule.amountMode == RecurringAmountMode.fixed)
                  SwitchListTile(
                    key: const ValueKey('recurring-auto-record'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.record.repeat.autoRecordLabel),
                    subtitle: Text(t.record.repeat.autoRecordHint),
                    value: rule.autoRecord,
                    onChanged: (value) => bloc.add(RecurringAutoRecordToggled(ruleId: rule.id, enabled: value)),
                  ),
                if (rule.kind == RecurringKind.expense)
                  ListTile(
                    key: const ValueKey('recurring-budget-link'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.recurring.budgetLinkLabel),
                    subtitle: Text(switch (linkedBudgetItem(rule, state.budgetOptions)) {
                      final item? => t.recurring.budgetLinkValue(item: item.itemName, budget: item.budgetName),
                      null => t.recurring.budgetLinkNone,
                    }),
                    trailing: const AppIcon(IconKey.chevronRight),
                    onTap: () => unawaited(_pickBudgetItem(context, rule, state)),
                  ),
                if (priceUp) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    t.recurring.priceUp(
                      amount: AppMoneyFormatter.format(last.amount),
                      usual: AppMoneyFormatter.format(rule.amount),
                    ),
                    style: textTheme.bodyMedium?.copyWith(color: colors.pending),
                  ),
                  AppButton.secondary(
                    label: t.recurring.priceUpdateAction(amount: AppMoneyFormatter.format(last.amount)),
                    onPressed: () => bloc.add(RecurringAmountUpdated(ruleId: rule.id, amount: last.amount)),
                  ),
                ],
                if (next.isNotEmpty && !rule.isPaused) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppSectionLabel(t.recurring.nextTitle),
                  for (final o in next)
                    _OccurrenceLine(
                      date: occurrenceDateText(o.date, today),
                      amount: AppMoneyFormatter.format(rule.amount),
                      skipped: o.status == OccurrenceStatus.skipped,
                      action: o.status == OccurrenceStatus.skipped
                          ? (
                              t.recurring.unskipAction,
                              () => bloc.add(RecurringOccurrenceUnskipped(ruleId: rule.id, date: o.date)),
                            )
                          : (
                              t.recurring.skipAction,
                              () => bloc.add(RecurringOccurrenceSkipped(ruleId: rule.id, date: o.date)),
                            ),
                    ),
                ],
                const SizedBox(height: AppSpacing.md),
                AppSectionLabel(t.recurring.recordedTitle),
                if (recorded.isEmpty)
                  Text(t.recurring.noRecorded, style: textTheme.bodySmall)
                else
                  for (final transaction in recorded.take(_historyCount))
                    _OccurrenceLine(
                      date: occurrenceDateText(transaction.recurrence!.occurrenceDate, today),
                      amount: AppMoneyFormatter.format(transaction.amount),
                      onTap: () => context.pushRoute(TransactionRouteKeys.detail, TransactionDetailInput(transaction)),
                    ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: t.recurring.editAction,
                  onPressed: () => context.pushRoute(RecordRouteKeys.sheet, RecordSheetInput(editRule: rule)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OccurrenceLine extends StatelessWidget {
  const _OccurrenceLine({required this.date, required this.amount, this.skipped = false, this.action, this.onTap});

  final String date;
  final String amount;
  final bool skipped;
  final (String, VoidCallback)? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: skipped ? colors.textMuted : null,
      decoration: skipped ? TextDecoration.lineThrough : null,
    );
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          SizedBox(width: 96, child: Text(date, style: style)),
          Expanded(child: Text(amount, style: style)),
          if (action case (final label, final onPressed)) TextButton(onPressed: onPressed, child: Text(label)),
          if (onTap != null) const AppIcon(IconKey.chevronRight, size: 18),
        ],
      ),
    );
    return onTap == null ? row : AppTappable(label: '$date $amount', onTap: onTap, child: row);
  }
}
