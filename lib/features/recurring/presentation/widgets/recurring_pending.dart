import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/recurring/di/recurring_scope.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_state.dart';
import 'package:saldough/features/recurring/presentation/recurring_display.dart';
import 'package:saldough/features/recurring/presentation/widgets/recurring_row.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:state_management/state_management.dart';

/// Baris kemunculan menunggu beserta aksinya (PLAN_TAB_LAYOUT §4.9):
/// **Lewati** dan **Catat**; ketuk barisnya = Ubah dulu (CATAT terisi).
/// Rutin bernominal kira-kira tidak bisa dicatat satu ketuk: Catat membuka
/// CATAT (ADR-035 §3.3).
class RecurringPendingTile extends StatelessWidget {
  /// Membuat [RecurringPendingTile].
  const RecurringPendingTile({
    required this.entry,
    required this.state,
    super.key,
  });

  /// Baris kelompok Menunggu.
  final RecurringEntry entry;

  /// State bloc, untuk nama dompet dan hari ini.
  final RecurringState state;

  void _editFirst(BuildContext context, DateTime date) => context.pushRoute(
    RecordRouteKeys.sheet,
    RecordSheetInput(occurrenceRule: entry.rule, occurrenceDate: date),
  );

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RecurringBloc>();
    final rule = entry.rule;
    final date = entry.occurrence!.date;
    final fixed = rule.amountMode == RecurringAmountMode.fixed;
    // E3 (ADR-037 §3.1): autodebet H+2 yang belum terlihat.
    // Label dan tautan dari notifikasi bagian otomasi R3: hanya untuk Plus
    // (ADR-041 §3.8).
    final plus = ActivePlan.isPlus;
    final unseen = plus && isUnseen(entry.occurrence!, today: state.today);
    // W3 dari notifikasi (ADR-037 §3.3): transaksinya ada tapi nominalnya
    // naik; Catat di sini akan menggandakannya, jadi tawarkan tautan.
    final raised = plus ? priceIncreaseCandidate(rule, date, state.transactions) : null;
    final days = state.today;
    final badge = DsBadge(
      label: dueText(date, days),
      tone: switch (dueStateOf(date, days)) {
        DueState.overdue => DsBadgeTone.warning,
        DueState.today => DsBadgeTone.warm,
        DueState.upcoming => DsBadgeTone.neutral,
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ketuk baris = Ubah dulu (PLAN_TAB_LAYOUT §4.9).
        RecurringRow(
          entry: entry,
          toWalletName: state.walletName(rule.toWalletId),
          today: state.today,
          badge: badge,
          onTap: () => _editFirst(context, date),
        ),
        // Aksi seragam selebar isi baris (sejajar judul): Lewati di kiri,
        // tindakan utama di kanan.
        Padding(
          padding: const EdgeInsets.fromLTRB(70, 0, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (raised != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    t.recurring.priceUpFound(name: rule.note, amount: AppMoneyFormatter.format(raised.amount)),
                    key: ValueKey('recurring-price-up-${rule.id}'),
                    style: context.ds.typography.bodySm.copyWith(color: context.ds.colors.textSecondary),
                  ),
                )
              else if (unseen)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    t.recurring.unseenLabel,
                    key: ValueKey('recurring-unseen-${rule.id}'),
                    style: context.ds.typography.bodySm.copyWith(color: context.ds.colors.textSecondary),
                  ),
                ),
              DsInlineActions(
                actions: [
                  DsInlineAction(
                    label: t.recurring.skipAction,
                    onPressed: () => bloc.add(RecurringOccurrenceSkipped(ruleId: rule.id, date: date)),
                  ),
                  if (raised != null) ...[
                    DsInlineAction(
                      label: t.recurring.priceUpKeep,
                      onPressed: () {
                        AppAnalytics.log(RecurringEvents.priceIncreaseAction('keep'));
                        bloc.add(RecurringOccurrenceLinked(ruleId: rule.id, date: date, transactionId: raised.id));
                      },
                    ),
                    DsInlineAction(
                      tone: DsInlineActionTone.primary,
                      label: t.recurring.priceUpUpdate,
                      onPressed: () {
                        AppAnalytics.log(RecurringEvents.priceIncreaseAction('update'));
                        bloc
                          ..add(RecurringOccurrenceLinked(ruleId: rule.id, date: date, transactionId: raised.id))
                          ..add(RecurringAmountUpdated(ruleId: rule.id, amount: raised.amount));
                      },
                    ),
                  ] else ...[
                    if (unseen)
                      DsInlineAction(
                        label: t.recurring.notYetAction,
                        onPressed: () => bloc.add(RecurringOccurrenceSnoozed(ruleId: rule.id)),
                      )
                    else if (fixed)
                      DsInlineAction(label: t.recurring.editFirstAction, onPressed: () => _editFirst(context, date)),
                    DsInlineAction(
                      tone: DsInlineActionTone.primary,
                      label: t.recurring.recordAction,
                      onPressed: fixed
                          ? () => bloc.add(RecurringOccurrenceRecorded(ruleId: rule.id, date: date))
                          : () => _editFirst(context, date),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kelompok **Menunggu dicatat** di segmen Rutin: kartu bernuansa aksi
/// dengan kepala (jumlah dan total) lalu tiap kemunculan beserta aksinya.
/// Baris pertama bisa jadi target tur ([firstSpotlight]).
class RecurringPendingGroup extends StatelessWidget {
  /// Membuat [RecurringPendingGroup].
  const RecurringPendingGroup({required this.rows, required this.state, this.firstSpotlight, super.key});

  /// Kemunculan menunggu, urut terlama dulu.
  final List<RecurringEntry> rows;

  /// State bloc.
  final RecurringState state;

  /// Kunci tur untuk baris pertama.
  final SpotlightKey? firstSpotlight;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final total = rows.fold<int>(0, (sum, e) => sum + e.rule.amount);
    final approximate = rows.any((e) => e.rule.amountMode == RecurringAmountMode.estimated);
    final totalText = '${approximate ? '≈' : ''}${AppMoneyFormatter.format(total)}';
    return DecoratedBox(
      decoration: ds.elevation.card.decoration().copyWith(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.actionPrimary.withValues(alpha: 0.10), c.surfaceCard],
          stops: const [0, 0.35],
        ),
        border: Border.all(color: c.actionPrimary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                DsIdleMotion(
                  kind: DsIdleKind.float,
                  child: DsIconTile.asset(
                    asset: ClayIcons.alarm,
                    tone: DsIconTileTone.warning,
                    size: DsIconTileSize.sm,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(t.recurring.pendingTotal(amount: totalText), style: ds.typography.titleMd),
                  ),
                ),
                const SizedBox(width: 8),
                DsBadge(label: '${rows.length}', tone: DsBadgeTone.warm),
              ],
            ),
          ),
          for (final (i, entry) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 14, endIndent: 14, color: c.outlineSubtle),
            DsReveal(
              index: i,
              child: SpotlightTarget(
                spotlightKey: i == 0 ? firstSpotlight : null,
                child: RecurringPendingTile(entry: entry, state: state),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kemunculan menunggu dari [state], urut tanggal terlama dulu.
List<RecurringEntry> pendingEntries(RecurringState state) => [
  for (final entry in recurringEntries(
    state.rules,
    windowStart: DateTime(state.today.year, state.today.month - 1),
    monthStart: state.monthStart,
    monthEnd: state.monthEnd,
    today: state.today,
    transactions: state.transactions,
  ))
    if (entry.group == RecurringGroup.pending) entry,
];

/// Tombol **Catat semua** bila ada dua atau lebih kemunculan menunggu yang
/// bisa dicatat satu ketuk.
Widget? recordAllButton(BuildContext context, List<RecurringEntry> pending) {
  final fixed = pending.where((e) => e.rule.amountMode == RecurringAmountMode.fixed).length;
  if (fixed < 2) return null;
  return DsButton.secondary(
    label: t.recurring.recordAllAction,
    icon: Icons.done_all,
    expand: true,
    onPressed: () => context.read<RecurringBloc>().add(const RecurringPendingRecordedAll()),
  );
}

/// Kartu **Menunggu dicatat** di Beranda (T-15.6, J3): paling banyak tiga
/// kemunculan, Catat semua, dan Lihat semua ke segmen Rutin. Tidak tampil
/// bila tidak ada yang menunggu. Memasang `RecurringScope`-nya sendiri dari
/// [container] akar (pola `CaptureInboxBanner`).
class RecurringPendingCard extends StatelessWidget {
  /// Membuat [RecurringPendingCard].
  const RecurringPendingCard({
    required this.container,
    required this.onShowAll,
    this.spotlight,
    this.board,
    super.key,
  });

  /// Kontainer akar.
  final GetIt container;

  /// Membuka segmen Rutin.
  final VoidCallback onShowAll;

  /// Tur dan langkah yang menyorot kartu ini, atau `null`. Hanya untuk satu
  /// tempat pemakaian (Beranda): kunci spotlight hanya boleh satu target.
  final ({TourId tour, SpotlightKey key})? spotlight;

  /// Papan status Beranda (mode ringkas, ADR-043): tanpa menggambar kartu,
  /// hanya melapor satu slide "N menunggu dicatat" yang membuka segmen Rutin.
  /// Mencatat, Lewati, dan Catat semua tinggal di segmen Rutin. `null` =
  /// kartu penuh (dipakai juga di segmen Rutin).
  final DsStatusBoard? board;

  static const _statusId = 'recurring';

  static const _maxShown = 3;

  @override
  Widget build(BuildContext context) {
    return ScopeWidget<RecurringScope>(
      create: () => RecurringScope(parentContainer: container),
      builder: (context, scope) {
        final bloc = scope.container<RecurringBloc>();
        return BlocProvider.value(
          value: bloc,
          child: EffectListener<RecurringBloc, RecurringState>(
            child: RunOnce(
              action: () => bloc.add(const RecurringStarted()),
              child: BlocBuilder<RecurringBloc, RecurringState>(
                builder: (context, state) {
                  final board = this.board;
                  Widget hidden() =>
                      board == null ? const SizedBox.shrink() : DsStatusReport(board: board, id: _statusId, data: null);
                  if (state.isLoading || state.loadFailed) return hidden();
                  final pending = pendingEntries(state);
                  if (pending.isEmpty) return hidden();
                  if (board != null) {
                    final first = pending.first.rule.note;
                    return DsStatusReport(
                      board: board,
                      id: _statusId,
                      data: DsStatusSlideData(
                        id: _statusId,
                        icon: Icons.event_note_outlined,
                        asset: ClayIcons.calendar,
                        title: '${t.recurring.pendingCardTitle} (${pending.length})',
                        subtitle: pending.length == 1
                            ? first
                            : t.recurring.pendingMore(name: first, n: pending.length - 1),
                        actionLabel: t.recurring.seeAllAction,
                        onAction: onShowAll,
                        attention: true,
                      ),
                    );
                  }
                  final recordAll = recordAllButton(context, pending);
                  // Prototipe `BerandaRutin.dc.html`: judul bagian dengan tautan
                  // ke segmen Rutin, kartu daftar kemunculan menunggu.
                  final card = Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: SpotlightTarget(
                      spotlightKey: spotlight?.key,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DsSectionHeader(
                            title: '${t.recurring.pendingCardTitle} (${pending.length})',
                            actionLabel: t.recurring.seeAllAction,
                            onAction: onShowAll,
                          ),
                          const SizedBox(height: 8),
                          DsListCard(
                            children: [
                              for (final entry in pending.take(_maxShown))
                                RecurringPendingTile(
                                  entry: entry,
                                  state: state,
                                ),
                            ],
                          ),
                          if (recordAll != null) ...[
                            const SizedBox(height: 8),
                            recordAll,
                          ],
                        ],
                      ),
                    ),
                  );
                  // Kartu ini dimuat sesudah layarnya: picu turnya sendiri
                  // agar disorot sekali saat pertama tampil.
                  return switch (spotlight) {
                    final spotlight? => TourTrigger(
                      tour: spotlight.tour,
                      ready: true,
                      child: card,
                    ),
                    null => card,
                  };
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
