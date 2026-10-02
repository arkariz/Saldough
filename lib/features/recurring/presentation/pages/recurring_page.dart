import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/recurring/di/recurring_scope.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_state.dart';
import 'package:saldough/features/recurring/presentation/navigation/recurring_route_keys.dart';
import 'package:saldough/features/recurring/presentation/widgets/recurring_pending.dart';
import 'package:saldough/features/recurring/presentation/widgets/recurring_row.dart';
import 'package:saldough/features/recurring/presentation/widgets/recurring_starter_chips.dart';
import 'package:saldough/features/recurring/presentation/widgets/recurring_summary_card.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:state_management/state_management.dart';

/// Segmen **Rutin** tab Rencana (T-14.5, PLAN_TAB_LAYOUT §6). Memasang
/// `RecurringScope`-nya sendiri, jadi shell cukup menaruh widget ini di
/// segmennya.
///
/// [container] adalah kontainer akar: di dalam shell, `ScopeProvider`
/// terdekat milik scope tab lain (pola `CaptureInboxBanner`).
class RecurringPage extends StatelessWidget {
  /// Membuat [RecurringPage].
  const RecurringPage({this.container, super.key});

  /// Kontainer induk scope; bawaan `ScopeProvider` terdekat.
  final GetIt? container;

  @override
  Widget build(BuildContext context) {
    final parentContainer = container ?? ScopeProvider.of(context);
    return ScopeWidget<RecurringScope>(
      create: () => RecurringScope(parentContainer: parentContainer),
      builder: (context, scope) {
        final bloc = scope.container<RecurringBloc>();
        return BlocProvider.value(
          value: bloc,
          child: EffectListener<RecurringBloc, RecurringState>(
            child: RunOnce(action: () => bloc.add(const RecurringStarted()), child: const RecurringSegmentView()),
          ),
        );
      },
    );
  }
}

/// Isi segmen Rutin di atas `RecurringBloc` yang sudah terpasang.
class RecurringSegmentView extends StatelessWidget {
  /// Membuat [RecurringSegmentView].
  const RecurringSegmentView({super.key});

  static void _add(BuildContext context) =>
      context.pushRoute(RecordRouteKeys.sheet, const RecordSheetInput(repeat: RecurringPattern()));

  static void _open(BuildContext context, String ruleId) =>
      context.pushRoute(RecurringRouteKeys.detail, RecurringDetailInput(ruleId: ruleId));

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecurringBloc, RecurringState>(
      builder: (context, state) {
        if (state.isLoading) return const AppSkeletonPage();
        if (state.loadFailed) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(t.recurring.loadError),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: t.recurring.retryAction,
                onPressed: () => context.read<RecurringBloc>().add(const RecurringStarted()),
              ),
            ],
          );
        }
        const padding = EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.fabClearance);
        if (state.rules.isEmpty) {
          return ListView(
            padding: padding,
            children: [
              AppHardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.recurring.emptyTitle, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(t.recurring.emptyBody, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.md),
                    const RecurringStarterChips(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(label: t.recurring.addAction, onPressed: () => _add(context)),
            ],
          );
        }

        final entries = recurringEntries(
          state.rules,
          windowStart: DateTime(state.today.year, state.today.month - 1),
          monthStart: state.monthStart,
          monthEnd: state.monthEnd,
          today: state.today,
          transactions: state.transactions,
        );
        final summary = summarizeRecurringMonth(
          state.rules,
          from: state.monthStart,
          until: state.monthEnd,
          today: state.today,
          transactions: state.transactions,
        );
        int count(RecurringKind? kind) =>
            kind == null ? state.rules.length : state.rules.where((r) => r.kind == kind).length;
        final filter = state.kindFilter;
        final visible = [
          for (final e in entries)
            if (filter == null || e.rule.kind == filter) e,
        ];
        final bloc = context.read<RecurringBloc>();
        return ListView(
          padding: padding,
          children: [
            RecurringSummaryCard(
              summary: summary,
              month: state.monthStart,
              subscriptions: subscriptionTotals(state.rules),
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (kind, label) in [
                    (null, t.recurring.filterAll(n: count(null))),
                    (RecurringKind.income, t.recurring.filterIncome(n: count(RecurringKind.income))),
                    (RecurringKind.expense, t.recurring.filterExpense(n: count(RecurringKind.expense))),
                    (RecurringKind.transfer, t.recurring.filterTransfer(n: count(RecurringKind.transfer))),
                  ]) ...[
                    AppChoiceChip(
                      label: label,
                      selected: filter == kind,
                      onTap: () => bloc.add(RecurringKindFilterChanged(kind)),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (visible.isEmpty) ...[
              Text(t.recurring.filteredEmpty),
              TextButton(
                onPressed: () => bloc.add(const RecurringKindFilterChanged(null)),
                child: Text(t.recurring.showAllAction),
              ),
            ] else
              for (final group in RecurringGroup.values)
                if (visible.where((e) => e.group == group).toList() case final rows when rows.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppSectionLabel('${_groupLabel(group)} (${rows.length})'),
                  if (group == RecurringGroup.pending) ...[
                    for (final entry in rows) RecurringPendingTile(entry: entry, state: state),
                    ?recordAllButton(context, rows),
                  ] else
                    for (final entry in rows)
                      RecurringRow(
                        entry: entry,
                        walletName: state.walletName(entry.rule.walletId),
                        toWalletName: state.walletName(entry.rule.toWalletId),
                        today: state.today,
                        onTap: () => _open(context, entry.rule.id),
                      ),
                ],
            const SizedBox(height: AppSpacing.md),
            AppButton.secondary(label: t.recurring.addAction, onPressed: () => _add(context)),
          ],
        );
      },
    );
  }

  static String _groupLabel(RecurringGroup group) => switch (group) {
    RecurringGroup.pending => t.recurring.groupPending,
    RecurringGroup.thisMonth => t.recurring.groupThisMonth,
    RecurringGroup.later => t.recurring.groupLater,
    RecurringGroup.paused => t.recurring.groupPaused,
    RecurringGroup.ended => t.recurring.groupEnded,
  };
}
