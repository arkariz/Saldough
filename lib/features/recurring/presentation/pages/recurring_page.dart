import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
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
      // Tiga bulan untuk saran Sepertinya rutin (ADR-037 §3.3).
      create: () => RecurringScope(parentContainer: parentContainer, monthsBack: suggestionMonths),
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
            padding: const EdgeInsets.all(AppSpacing.space4),
            children: [
              Text(t.recurring.loadError),
              const SizedBox(height: AppSpacing.space2),
              AppButton(
                label: t.recurring.retryAction,
                onPressed: () => context.read<RecurringBloc>().add(const RecurringStarted()),
              ),
            ],
          );
        }
        const padding = EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, AppSpacing.space12);
        // Sepertinya rutin (ADR-037 §3.3), juga saat belum ada rutin.
        final suggestions = suggestRecurring(
          state.transactions,
          today: state.today,
          rules: state.rules,
          dismissed: state.dismissedSuggestions,
        );
        if (state.rules.isEmpty) {
          return TourTrigger(
            tour: TourId.recurring,
            ready: true,
            child: ListView(
              padding: padding,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(t.recurring.emptyTitle, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.space1),
                      Text(t.recurring.emptyBody, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.space4),
                      const SpotlightTarget(
                        spotlightKey: SpotlightKey.recurringStarters,
                        child: RecurringStarterChips(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                if (suggestions.isNotEmpty) ...[
                  _SuggestionCard(suggestions: suggestions),
                  const SizedBox(height: AppSpacing.space4),
                ],
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
              const SizedBox(height: AppSpacing.space4),
              // W6 rutin menganggur: satu kartu, yang pertama (ADR-037 §3.1).
              if (idleRules(
                    state.rules,
                    windowStart: DateTime(state.today.year, state.today.month - 1),
                    today: state.today,
                    transactions: state.transactions,
                  ).firstOrNull
                  case final idle?) ...[
                _IdleCard(rule: idle),
                const SizedBox(height: AppSpacing.space4),
              ],
              if (state.autoRecorded.isNotEmpty) ...[
                _AutoRecordedCard(entries: state.autoRecorded),
                const SizedBox(height: AppSpacing.space4),
              ],
              if (suggestions.isNotEmpty) ...[
                _SuggestionCard(suggestions: suggestions),
                const SizedBox(height: AppSpacing.space4),
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
                      AppChip(
                        label: label,
                        selected: filter == kind,
                        onBg: true,
                        onTap: () => bloc.add(RecurringKindFilterChanged(kind)),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              if (visible.isEmpty) ...[
                Text(t.recurring.filteredEmpty, textAlign: TextAlign.center),
                AppButton.text(
                  label: t.recurring.showAllAction,
                  onPressed: () => bloc.add(const RecurringKindFilterChanged(null)),
                ),
              ] else
                for (final group in RecurringGroup.values)
                  if (visible.where((e) => e.group == group).toList() case final rows when rows.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space2),
                    if (group == RecurringGroup.paused || group == RecurringGroup.ended)
                      _FoldedGroup(
                        label: '${_groupLabel(group)} (${rows.length})',
                        children: [for (final entry in rows) _row(context, state, entry)],
                      )
                    else ...[
                      _GroupLabel(_groupLabel(group), dot: group == RecurringGroup.pending),
                      const SizedBox(height: AppSpacing.space2),
                      if (group == RecurringGroup.pending) ...[
                        AppListCard(
                          dividerIndent: AppListCard.tileIndent + AppSize.tile + AppSpacing.space3,
                          children: [
                            // Hanya baris pertama yang disorot.
                            for (final (i, entry) in rows.indexed)
                              SpotlightTarget(
                                spotlightKey: i == 0 ? SpotlightKey.recurringPending : null,
                                child: RecurringPendingTile(entry: entry, state: state),
                              ),
                          ],
                        ),
                        if (recordAllButton(context, rows) case final recordAll?) ...[
                          const SizedBox(height: AppSpacing.space2),
                          recordAll,
                        ],
                      ] else
                        AppListCard(
                          dividerIndent: AppListCard.tileIndent + AppSize.tile + AppSpacing.space3,
                          children: [for (final entry in rows) _row(context, state, entry)],
                        ),
                    ],
                  ],
              const SizedBox(height: AppSpacing.space4),
              SpotlightTarget(
                spotlightKey: SpotlightKey.recurringAdd,
                child: AppButton.secondary(
                  label: t.recurring.addAction,
                  icon: IconKey.add,
                  expand: true,
                  onPressed: () => _add(context),
                ),
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
          child: AppButton.text(
            label: widget.label,
            icon: _open ? IconKey.expandLess : IconKey.chevronRight,
            onPressed: () => setState(() => _open = !_open),
          ),
        ),
        if (_open) AppListCard(children: widget.children),
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
    return AppCard(
      key: ValueKey('recurring-idle-${rule.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.recurring.idleTitle(name: name), style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.space1),
          Text(t.recurring.idleBody, style: textTheme.bodySmall?.copyWith(color: context.appColors.ink2)),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.space1,
            children: [
              TextButton(
                onPressed: () {
                  AppAnalytics.log(RecurringEvents.idleAction('keep'));
                  bloc.add(RecurringIdleDismissed(rule.id));
                },
                child: Text(t.recurring.idleKeep),
              ),
              TextButton(
                onPressed: () {
                  AppAnalytics.log(RecurringEvents.idleAction('pause'));
                  bloc.add(RecurringPauseToggled(rule.id));
                },
                child: Text(t.recurring.pauseAction),
              ),
              TextButton(
                onPressed: () {
                  AppAnalytics.log(RecurringEvents.idleAction('end'));
                  bloc.add(RecurringEnded(rule.id));
                },
                child: Text(t.recurring.endAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kartu **Sepertinya rutin** (ADR-037 §3.3): Jadikan rutin membuka CATAT
/// lewat Jadikan Rutin (transaksi terbaru jadi kemunculan pertama).
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestions});

  final List<RecurringSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RecurringBloc>();
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      key: const ValueKey('recurring-suggestions'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.recurring.suggestTitle, style: textTheme.titleSmall),
          for (final s in suggestions) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              t.recurring.suggestLine(
                name: s.latest.note,
                amount: AppMoneyFormatter.format(s.latest.amount),
                day: s.latest.date.day,
              ),
              style: textTheme.bodyMedium,
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.space1,
              children: [
                TextButton(
                  onPressed: () {
                    AppAnalytics.log(RecurringEvents.suggestionAction('dismiss'));
                    bloc.add(RecurringSuggestionDismissed(s.key));
                  },
                  child: Text(t.recurring.suggestDismiss),
                ),
                TextButton(
                  key: ValueKey('recurring-suggest-${s.key}'),
                  onPressed: () {
                    AppAnalytics.log(RecurringEvents.suggestionAction('accept'));
                    unawaited(context.pushRoute(RecordRouteKeys.sheet, RecordSheetInput(makeRecurringFrom: s.latest)));
                  },
                  child: Text(t.recurring.suggestAccept),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Daftar **Tercatat otomatis** 7 hari terakhir dengan Batalkan per baris
/// (ADR-037 §3.2).
class _AutoRecordedCard extends StatelessWidget {
  const _AutoRecordedCard({required this.entries});

  final List<AutoRecordEntry> entries;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RecurringBloc>();
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      key: const ValueKey('recurring-auto-recorded'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.recurring.autoRecordedTitle, style: textTheme.titleSmall),
          for (final e in entries)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${e.ruleName.isEmpty ? t.record.repeat.fallbackName : e.ruleName} · '
                    '${CycleMonthFormatter.formatDayMonth(e.occurrenceDate)}',
                    style: textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => bloc.add(RecurringAutoRecordUndone(e)),
                  child: Text(t.recurring.undoAction),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Label kelompok di daftar Rutin (`rencana.css` `.group-label`): `label`
/// `ink2`, titik `brand` untuk Menunggu dicatat.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label, {this.dot = false});

  final String label;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
      child: Row(
        children: [
          if (dot) ...[Container(width: 8, height: 8, color: colors.brand), const SizedBox(width: 6)],
          Flexible(
            child: Semantics(
              header: true,
              child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.ink2)),
            ),
          ),
        ],
      ),
    );
  }
}
