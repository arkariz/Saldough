import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
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
import 'package:saldough/features/recurring/presentation/widgets/reminder_nudge_card.dart';
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
            child: RunOnce(
              action: () => bloc.add(const RecurringStarted()),
              child: RecurringSegmentView(rootContainer: parentContainer),
            ),
          ),
        );
      },
    );
  }
}

/// Isi segmen Rutin di atas `RecurringBloc` yang sudah terpasang.
class RecurringSegmentView extends StatelessWidget {
  /// Membuat [RecurringSegmentView].
  const RecurringSegmentView({this.rootContainer, super.key});

  /// Kontainer akar untuk kartu tombol pengingat (Fase 21); `null` = tanpa.
  final GetIt? rootContainer;

  static void _add(BuildContext context) =>
      context.pushRoute(RecordRouteKeys.sheet, const RecordSheetInput(repeat: RecurringPattern()));

  static void _open(BuildContext context, String ruleId) =>
      context.pushRoute(RecurringRouteKeys.detail, RecurringDetailInput(ruleId: ruleId));

  @override
  Widget build(BuildContext context) {
    // Paket berubah: saran dan rutin menganggur (otomasi R3) tampil atau hilang.
    return ValueListenableBuilder<PlanState>(
      valueListenable: ActivePlan.notifier,
      builder: (context, _, _) => _view(context),
    );
  }

  Widget _view(BuildContext context) {
    return BlocBuilder<RecurringBloc, RecurringState>(
      builder: (context, state) {
        if (state.isLoading) return const AppSkeletonPage();
        if (state.loadFailed) {
          return AppErrorState(
            title: t.recurring.loadError,
            retryLabel: t.recurring.retryAction,
            onRetry: () => context.read<RecurringBloc>().add(const RecurringStarted()),
          );
        }
        const padding = EdgeInsets.fromLTRB(16, 16, 16, 96);
        // Sepertinya rutin (ADR-037 §3.3), juga saat belum ada rutin.
        // Saran dan rutin menganggur bagian otomasi R3: hanya untuk Plus
        // (ADR-041 §3.8); datanya tidak disentuh.
        final plus = ActivePlan.isPlus;
        final idle = !plus
            ? null
            : idleRules(
                state.rules,
                windowStart: DateTime(state.today.year, state.today.month - 1),
                today: state.today,
                transactions: state.transactions,
              ).firstOrNull;
        final suggestions = !plus
            ? const <RecurringSuggestion>[]
            : suggestRecurring(
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
                // Ilustrasi kosong yang hidup; pemula rutin sebagai chip di
                // bawahnya, tombol tambah di akhir daftar.
                DsReveal(
                  child: DsCard(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      children: [
                        const DsEmptyHero(
                          asset: ClayIcons.calendar,
                          orbit: [ClayIcons.repeat, ClayIcons.alarm, ClayIcons.coins],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t.recurring.emptyTitle,
                          textAlign: TextAlign.center,
                          style: context.ds.typography.titleMd.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.recurring.emptyBody,
                          textAlign: TextAlign.center,
                          style: context.ds.typography.bodySm.copyWith(color: context.ds.colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const DsReveal(
                  index: 1,
                  child: SpotlightTarget(spotlightKey: SpotlightKey.recurringStarters, child: RecurringStarterChips()),
                ),
                const SizedBox(height: 16),
                if (suggestions.isNotEmpty) ...[
                  _SuggestionCard(suggestions: suggestions),
                  const SizedBox(height: 16),
                ],
                SpotlightTarget(
                  spotlightKey: SpotlightKey.recurringAdd,
                  child: DsButton(
                    label: t.recurring.addAction,
                    icon: Icons.add,
                    expand: true,
                    onPressed: () => _add(context),
                  ),
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
        final ds = context.ds;
        return TourTrigger(
          tour: TourId.recurring,
          ready: true,
          child: ListView(
            padding: padding,
            children: [
              SpotlightTarget(
                spotlightKey: SpotlightKey.recurringSummary,
                child: DsReveal(
                  child: RecurringSummaryCard(
                    summary: summary,
                    // Nama periode (P-11): "Okt", atau rentang bila bukan bulan kalender.
                    monthLabel: state.period.shortName,
                    subscriptions: subscriptionTotals(state.rules),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Tombol permanen pengingat (FEATURE_DISCOVERY P-1): di bawah
              // kartu sisa tagihan, hilang begitu efektif.
              if (rootContainer case final root?) ReminderNudgeCard(container: root, bottomGap: true),
              // W6 rutin menganggur: satu kartu, yang pertama (ADR-037 §3.1).
              if (idle != null) ...[_IdleCard(rule: idle), const SizedBox(height: 16)],
              if (state.autoRecorded.isNotEmpty) ...[
                _AutoRecordedCard(entries: state.autoRecorded),
                const SizedBox(height: 16),
              ],
              if (suggestions.isNotEmpty) ...[_SuggestionCard(suggestions: suggestions), const SizedBox(height: 16)],
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
                      DsFilterChip(
                        label: label,
                        selected: filter == kind,
                        onTap: () => bloc.add(RecurringKindFilterChanged(kind)),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (visible.isEmpty)
                DsReveal(
                  child: DsCard(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Column(
                      children: [
                        const DsEmptyHero(asset: ClayIcons.emptyTray, orbit: [ClayIcons.tag], size: 104),
                        const SizedBox(height: 8),
                        Text(t.recurring.filteredEmpty, textAlign: TextAlign.center, style: ds.typography.titleMd),
                        const SizedBox(height: 12),
                        DsButton.ghost(
                          label: t.recurring.showAllAction,
                          onPressed: () => bloc.add(const RecurringKindFilterChanged(null)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final group in RecurringGroup.values)
                  if (visible.where((e) => e.group == group).toList() case final rows when rows.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    if (group == RecurringGroup.paused || group == RecurringGroup.ended)
                      _FoldedGroup(
                        label: '${_groupLabel(group)} (${rows.length})',
                        children: [for (final entry in rows) _row(context, state, entry)],
                      )
                    else ...[
                      _GroupLabel(_groupLabel(group), dot: group == RecurringGroup.pending),
                      const SizedBox(height: 8),
                      if (group == RecurringGroup.pending) ...[
                        RecurringPendingGroup(
                          rows: rows,
                          state: state,
                          firstSpotlight: SpotlightKey.recurringPending,
                        ),
                        if (recordAllButton(context, rows) case final recordAll?) ...[
                          const SizedBox(height: 8),
                          recordAll,
                        ],
                      ] else
                        DsListCard(
                          children: [
                            for (final (i, entry) in rows.indexed)
                              DsReveal(index: i, child: _row(context, state, entry)),
                          ],
                        ),
                    ],
                  ],
              const SizedBox(height: 16),
              SpotlightTarget(
                spotlightKey: SpotlightKey.recurringAdd,
                child: DsButton.secondary(
                  label: t.recurring.addAction,
                  icon: Icons.add,
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
          child: DsButton.ghost(
            label: widget.label,
            icon: _open ? Icons.expand_less : Icons.chevron_right,
            onPressed: () => setState(() => _open = !_open),
          ),
        ),
        AnimatedSize(
          duration: DsMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _open ? DsListCard(children: widget.children) : const SizedBox(width: double.infinity),
        ),
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
    final ds = context.ds;
    final name = rule.note.isEmpty ? t.record.repeat.fallbackName : rule.note;
    return DsReveal(
      child: DsCard(
        key: ValueKey('recurring-idle-${rule.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DsIconTile.asset(asset: ClayIcons.hourglass, tone: DsIconTileTone.warning, size: DsIconTileSize.sm),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.recurring.idleTitle(name: name), style: ds.typography.titleMd),
                      const SizedBox(height: 2),
                      Text(
                        t.recurring.idleBody,
                        style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              children: [
                DsButton.ghost(
                  label: t.recurring.idleKeep,
                  onPressed: () {
                    AppAnalytics.log(RecurringEvents.idleAction('keep'));
                    bloc.add(RecurringIdleDismissed(rule.id));
                  },
                ),
                DsButton.ghost(
                  label: t.recurring.pauseAction,
                  onPressed: () {
                    AppAnalytics.log(RecurringEvents.idleAction('pause'));
                    bloc.add(RecurringPauseToggled(rule.id));
                  },
                ),
                DsButton.ghost(
                  label: t.recurring.endAction,
                  onPressed: () {
                    AppAnalytics.log(RecurringEvents.idleAction('end'));
                    bloc.add(RecurringEnded(rule.id));
                  },
                ),
              ],
            ),
          ],
        ),
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
    final ds = context.ds;
    return DsReveal(
      index: 1,
      child: DsCard(
        key: const ValueKey('recurring-suggestions'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DsIdleMotion(
                  kind: DsIdleKind.float,
                  child: DsIconTile.asset(asset: ClayIcons.repeat, tone: DsIconTileTone.info, size: DsIconTileSize.sm),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(t.recurring.suggestTitle, style: ds.typography.titleMd)),
              ],
            ),
            for (final s in suggestions) ...[
              const SizedBox(height: 10),
              Text(
                t.recurring.suggestLine(
                  name: s.latest.note,
                  amount: AppMoneyFormatter.format(s.latest.amount),
                  day: s.latest.date.day,
                ),
                style: ds.typography.bodyMd,
              ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                children: [
                  DsButton.ghost(
                    label: t.recurring.suggestDismiss,
                    onPressed: () {
                      AppAnalytics.log(RecurringEvents.suggestionAction('dismiss'));
                      bloc.add(RecurringSuggestionDismissed(s.key));
                    },
                  ),
                  DsButton.compact(
                    key: ValueKey('recurring-suggest-${s.key}'),
                    label: t.recurring.suggestAccept,
                    onPressed: () {
                      AppAnalytics.log(RecurringEvents.suggestionAction('accept'));
                      unawaited(
                        context.pushRoute(RecordRouteKeys.sheet, RecordSheetInput(makeRecurringFrom: s.latest)),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
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
    final ds = context.ds;
    return DsReveal(
      child: DsCard(
        key: const ValueKey('recurring-auto-recorded'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DsIconTile.asset(asset: ClayIcons.done, tone: DsIconTileTone.income, size: DsIconTileSize.sm),
                const SizedBox(width: 12),
                Expanded(child: Text(t.recurring.autoRecordedTitle, style: ds.typography.titleMd)),
              ],
            ),
            for (final e in entries)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${e.ruleName.isEmpty ? t.record.repeat.fallbackName : e.ruleName} · '
                      '${CycleMonthFormatter.formatDayMonth(e.occurrenceDate)}',
                      style: ds.typography.bodyMd,
                    ),
                  ),
                  DsButton.ghost(
                    label: t.recurring.undoAction,
                    onPressed: () => bloc.add(RecurringAutoRecordUndone(e)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Label kelompok di daftar Rutin: judul kapital kecil, titik aksi yang
/// berdenyut untuk Menunggu dicatat.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label, {this.dot = false});

  final String label;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          if (dot) ...[
            DsPulse(
              borderRadius: DsRadius.fullAll,
              child: DecoratedBox(
                decoration: BoxDecoration(color: c.actionPrimary, shape: BoxShape.circle),
                child: const SizedBox.square(dimension: 8),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Semantics(
              header: true,
              child: Text(label.toUpperCase(), style: ds.typography.pixelCaption.copyWith(color: c.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}
