import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
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

/// Segmen **Rutin** tab Rencana (T-15.5, PLAN_TAB_LAYOUT §6). Memasang
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
          return TourTrigger(
            tour: TourId.recurring,
            ready: true,
            child: ListView(
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
                      const SpotlightTarget(
                        spotlightKey: SpotlightKey.recurringStarters,
                        child: RecurringStarterChips(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SpotlightTarget(
                  spotlightKey: SpotlightKey.recurringAdd,
                  child: AppButton(label: t.recurring.addAction, onPressed: () => _add(context)),
                ),
              ],
            ),
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
        final filter = state.kindFilter;
        final visible = [
          for (final e in entries)
            if (filter == null || e.rule.kind == filter) e,
        ];
        final bloc = context.read<RecurringBloc>();
        return TourTrigger(
          tour: TourId.recurring,
          ready: true,
          child: ListView(
            padding: padding,
            children: [
              SpotlightTarget(
                spotlightKey: SpotlightKey.recurringSummary,
                child: RecurringSummaryCard(
                  summary: summary,
                  monthLabel: CycleMonthFormatter.formatMonthShort(state.monthStart),
                  subscriptions: subscriptionTotals(state.rules),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // W6 rutin menganggur: satu kartu, yang pertama (ADR-037 §3.1).
              if (idleRules(
                    state.rules,
                    windowStart: DateTime(state.today.year, state.today.month - 1),
                    today: state.today,
                    transactions: state.transactions,
                  ).firstOrNull
                  case final idle?) ...[
                _IdleCard(rule: idle),
                const SizedBox(height: AppSpacing.md),
              ],
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Tanpa angka hitungan (PLAN_TAB_LAYOUT §4.9).
                    for (final (kind, label) in [
                      (null, t.recurring.chipAll),
                      (RecurringKind.income, t.recurring.chipIncome),
                      (RecurringKind.expense, t.recurring.chipExpense),
                      (RecurringKind.transfer, t.recurring.chipTransfer),
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
                    if (group == RecurringGroup.paused || group == RecurringGroup.ended)
                      _FoldedGroup(
                        label: '${_groupLabel(group)} (${rows.length})',
                        children: [for (final entry in rows) _row(context, state, entry)],
                      )
                    else ...[
                      AppSectionLabel(_groupLabel(group)),
                      if (group == RecurringGroup.pending) ...[
                        // Hanya baris pertama yang disorot.
                        for (final (i, entry) in rows.indexed)
                          SpotlightTarget(
                            spotlightKey: i == 0 ? SpotlightKey.recurringPending : null,
                            child: RecurringPendingTile(entry: entry, state: state),
                          ),
                        ?recordAllButton(context, rows),
                      ] else
                        for (final entry in rows) _row(context, state, entry),
                    ],
                  ],
              const SizedBox(height: AppSpacing.md),
              SpotlightTarget(
                spotlightKey: SpotlightKey.recurringAdd,
                child: AppButton.secondary(label: t.recurring.addAction, onPressed: () => _add(context)),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _row(BuildContext context, RecurringState state, RecurringEntry entry) => RecurringRow(
    entry: entry,
    toWalletName: state.walletName(entry.rule.toWalletId),
    today: state.today,
    onTap: () => _open(context, entry.rule.id),
  );

  static String _groupLabel(RecurringGroup group) => switch (group) {
    RecurringGroup.pending => t.recurring.groupPending,
    RecurringGroup.thisMonth => t.recurring.groupThisMonth,
    RecurringGroup.later => t.recurring.groupLater,
    RecurringGroup.paused => t.recurring.groupPaused,
    RecurringGroup.ended => t.recurring.groupEnded,
  };
}

/// Kelompok Dijeda/Selesai: terlipat, cukup satu baris "Selesai (1) ›".
class _FoldedGroup extends StatefulWidget {
  const _FoldedGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  State<_FoldedGroup> createState() => _FoldedGroupState();
}

class _FoldedGroupState extends State<_FoldedGroup> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _open = !_open),
            child: Text('${widget.label} ${_open ? '⌄' : '›'}'),
          ),
        ),
        if (_open) ...widget.children,
      ],
    );
  }
}

/// Kartu "Masih memakai Spotify?" (W6): Biarkan / Jeda / Akhiri.
class _IdleCard extends StatelessWidget {
  const _IdleCard({required this.rule});

  final RecurringRule rule;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RecurringBloc>();
    final textTheme = Theme.of(context).textTheme;
    final name = rule.note.isEmpty ? t.record.repeat.fallbackName : rule.note;
    return AppHardCard(
      key: ValueKey('recurring-idle-${rule.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.recurring.idleTitle(name: name), style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(t.recurring.idleBody, style: textTheme.bodySmall?.copyWith(color: context.appColors.textMuted)),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.xs,
            children: [
              TextButton(onPressed: () => bloc.add(RecurringIdleDismissed(rule.id)), child: Text(t.recurring.idleKeep)),
              TextButton(
                onPressed: () => bloc.add(RecurringPauseToggled(rule.id)),
                child: Text(t.recurring.pauseAction),
              ),
              TextButton(onPressed: () => bloc.add(RecurringEnded(rule.id)), child: Text(t.recurring.endAction)),
            ],
          ),
        ],
      ),
    );
  }
}
