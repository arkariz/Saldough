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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6, vertical: AppSpacing.space2),
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
                RecurringKind.expense => IconKey.categoryOther,
                RecurringKind.transfer => IconKey.transfer,
              };
        final kindLabel = switch (rule.kind) {
          RecurringKind.income => t.record.kindIncome,
          RecurringKind.expense => t.record.kindExpense,
          RecurringKind.transfer => t.record.kindTransfer,
        };
        final moneyKind = switch (rule.kind) {
          RecurringKind.income => MoneyKind.income,
          RecurringKind.expense => MoneyKind.expense,
          RecurringKind.transfer => MoneyKind.transfer,
        };
        final lastDate = lastOccurrence(rule);
        return Scaffold(
          appBar: AppBar(
            title: Text(rule.note.isEmpty ? t.record.repeat.fallbackName : rule.note),
            actions: [
              PopupMenuButton<_MenuAction>(
                tooltip: t.recurring.moreActions,
                icon: AppIcon(IconKey.moreVert, color: colors.ink),
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
          bottomNavigationBar: AppStickyBar(
            child: AppButton(
              expand: true,
              icon: IconKey.edit,
              label: t.recurring.editAction,
              onPressed: () => context.pushRoute(RecordRouteKeys.sheet, RecordSheetInput(editRule: rule)),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.space4, 0, AppSpacing.space4, AppSpacing.space6),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          AppIconTile(icon),
                          const SizedBox(width: AppSpacing.space3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  [kindLabel, ?category?.name].join(' · '),
                                  style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                                ),
                                // Nominal kira-kira memakai tanda ≈ dari `signedAmount`.
                                if (rule.amountMode == RecurringAmountMode.estimated)
                                  Text(
                                    signedAmount(rule.kind, rule.amount, approximate: true),
                                    style: context.numberStyles.amountLg.copyWith(color: colors.ink),
                                  )
                                else
                                  AppMoneyText(rule.amount, kind: moneyKind, size: MoneySize.large),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.space2),
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
                        const SizedBox(height: AppSpacing.space2),
                        _InstallmentProgress(done: done, total: total),
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          t.recurring.progressLine(k: done, n: total),
                          style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                        ),
                      ],
                      // W7 bebas cicilan (ADR-036 §3.7).
                      if (installmentFreeOf(rule, today: today) case final free?) ...[
                        const SizedBox(height: AppSpacing.space3),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.space3),
                          decoration: ShapeDecoration(
                            color: colors.surface2,
                            shape: const PixelCornerBorder.small(),
                          ),
                          child: Text(
                            t.recurring.installmentFreeLine(
                              month: CycleMonthFormatter.formatMonthYearShort(free.from),
                              amount: AppMoneyFormatter.format(free.perMonth),
                            ),
                            key: const ValueKey('recurring-installment-free'),
                            style: textTheme.bodyMedium?.copyWith(color: colors.positive),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (priceUp) ...[
                  const SizedBox(height: AppSpacing.space4),
                  AppBanner(
                    message: t.recurring.priceUp(
                      amount: AppMoneyFormatter.format(last.amount),
                      usual: AppMoneyFormatter.format(rule.amount),
                    ),
                    icon: IconKey.warning,
                    actionLabel: t.recurring.priceUpdateAction(amount: AppMoneyFormatter.format(last.amount)),
                    onAction: () => bloc.add(RecurringAmountUpdated(ruleId: rule.id, amount: last.amount)),
                  ),
                ],
                const SizedBox(height: AppSpacing.space6),
                AppSectionHeader(t.recurring.settingsTitle),
                AppListCard(
                  dividerIndent: AppListCard.plainIndent,
                  children: [
                    MergeSemantics(
                      child: AppListRow(
                        compact: true,
                        title: t.recurring.ruleRemindersLabel,
                        trailing: Switch(
                          value: rule.reminders,
                          onChanged: (value) => bloc.add(RecurringRemindersToggled(ruleId: rule.id, enabled: value)),
                        ),
                      ),
                    ),
                    if (rule.amountMode == RecurringAmountMode.fixed)
                      MergeSemantics(
                        child: AppListRow(
                          compact: true,
                          wrapTitle: true,
                          wrapSubtitle: true,
                          title: t.record.repeat.autoRecordLabel,
                          subtitle: t.record.repeat.autoRecordHint,
                          trailing: Switch(
                            key: const ValueKey('recurring-auto-record'),
                            value: rule.autoRecord,
                            onChanged: (value) =>
                                bloc.add(RecurringAutoRecordToggled(ruleId: rule.id, enabled: value)),
                          ),
                        ),
                      ),
                    if (rule.kind == RecurringKind.expense)
                      AppListRow(
                        key: const ValueKey('recurring-budget-link'),
                        compact: true,
                        wrapSubtitle: true,
                        chevron: true,
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
                  const SizedBox(height: AppSpacing.space6),
                  AppSectionHeader(t.recurring.nextTitle),
                  AppListCard(
                    dividerIndent: AppListCard.plainIndent,
                    children: [
                      for (final o in next)
                        _OccurrenceLine(
                          date: o.date,
                          today: today,
                          title: occurrenceDateText(o.date, today),
                          amount: rule.amount,
                          kind: moneyKind,
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
                  ),
                ],
                const SizedBox(height: AppSpacing.space6),
                AppSectionHeader(t.recurring.recordedTitle),
                if (recorded.isEmpty)
                  Text(t.recurring.noRecorded, style: textTheme.bodyMedium?.copyWith(color: colors.ink2))
                else
                  AppListCard(
                    dividerIndent: AppListCard.plainIndent,
                    children: [
                      for (final transaction in recorded.take(_historyCount))
                        _OccurrenceLine(
                          date: transaction.recurrence!.occurrenceDate,
                          today: today,
                          title: occurrenceDateText(transaction.recurrence!.occurrenceDate, today),
                          amount: transaction.amount,
                          kind: moneyKind,
                          muted: true,
                          onTap: () =>
                              context.pushRoute(TransactionRouteKeys.detail, TransactionDetailInput(transaction)),
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

/// Baris label–nilai di kartu kepala (`inset__row`).
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodyMedium?.copyWith(color: context.appColors.ink2)),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Text(value, textAlign: TextAlign.end, style: textTheme.bodyMedium?.copyWith(color: context.appColors.ink)),
          ),
        ],
      ),
    );
  }
}

/// Progres cicilan sebagai kotak per kemunculan (prototipe: 12 kotak, yang
/// tercatat `brand`). Lebih dari 24 kali memakai [AppProgressBar].
class _InstallmentProgress extends StatelessWidget {
  const _InstallmentProgress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (total > 24) return AppProgressBar(value: (done / total).clamp(0, 1).toDouble());
    return Semantics(
      label: t.recurring.progressLine(k: done, n: total),
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(child: Container(height: 10, color: i < done ? colors.brand : colors.surface2)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Baris jadwal (`rencana.css` `.sched`): kolom tanggal, judul, nominal,
/// lalu aksi (Lewati) atau panah. Yang dilewati dicoret; yang tercatat
/// diredupkan.
class _OccurrenceLine extends StatelessWidget {
  const _OccurrenceLine({
    required this.date,
    required this.today,
    required this.title,
    required this.amount,
    required this.kind,
    this.skipped = false,
    this.muted = false,
    this.action,
    this.onTap,
  });

  final DateTime date;
  final DateTime today;
  final String title;
  final int amount;
  final MoneyKind kind;
  final bool skipped;
  final bool muted;
  final (String, VoidCallback)? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final dim = skipped || muted;
    final ink = dim ? colors.ink3 : colors.ink;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.row),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space2,
          action == null ? AppSpacing.space4 : AppSpacing.space2,
          AppSpacing.space2,
        ),
        child: Row(
          children: [
            SizedBox(
              width: AppSize.tile,
              child: Column(
                children: [
                  Text(
                    '${date.day}',
                    style: context.numberStyles.amountLg.copyWith(fontSize: 18, height: 22 / 18, color: ink),
                  ),
                  Text(CycleMonthFormatter.formatMonthShort(date), style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: ink,
                  decoration: skipped ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            // Nominal mengecil di layar sempit supaya aksi tetap utuh.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: AppMoneyText(amount, kind: kind, color: dim ? colors.ink3 : null),
              ),
            ),
            if (action case (final label, final onPressed)) ...[
              const SizedBox(width: AppSpacing.space1),
              AppButton.text(small: true, label: label, onPressed: onPressed),
            ],
            if (onTap != null) ...[
              const SizedBox(width: AppSpacing.space1),
              AppIcon(IconKey.chevronRight, size: 20, color: colors.ink3),
            ],
          ],
        ),
      ),
    );
    return onTap == null ? row : AppTappable(label: title, onTap: onTap, child: row);
  }
}
