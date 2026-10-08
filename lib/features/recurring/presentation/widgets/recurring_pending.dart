import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/recurring/di/recurring_scope.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_state.dart';
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
    final unseen = isUnseen(entry.occurrence!, today: state.today);
    // W3 dari notifikasi (ADR-037 §3.3): transaksinya ada tapi nominalnya
    // naik; Catat di sini akan menggandakannya, jadi tawarkan tautan.
    final raised = priceIncreaseCandidate(rule, date, state.transactions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ketuk baris = Ubah dulu (PLAN_TAB_LAYOUT §4.9).
        RecurringRow(
          entry: entry,
          toWalletName: state.walletName(rule.toWalletId),
          today: state.today,
          onTap: () => _editFirst(context, date),
        ),
        if (raised != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: Text(
              t.recurring.priceUpFound(
                name: rule.note,
                amount: AppMoneyFormatter.format(raised.amount),
              ),
              key: ValueKey('recurring-price-up-${rule.id}'),
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.appColors.ink2),
            ),
          )
        else if (unseen)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: Text(
              t.recurring.unseenLabel,
              key: ValueKey('recurring-unseen-${rule.id}'),
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.appColors.ink2),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            0,
            AppSpacing.space4,
            AppSpacing.space2,
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space2,
            children: [
              AppButton.text(
                small: true,
                label: t.recurring.skipAction,
                onPressed: () => bloc.add(
                  RecurringOccurrenceSkipped(ruleId: rule.id, date: date),
                ),
              ),
              if (raised != null) ...[
                AppButton.text(
                  small: true,
                  label: t.recurring.priceUpKeep,
                  onPressed: () {
                    AppAnalytics.log(
                      RecurringEvents.priceIncreaseAction('keep'),
                    );
                    bloc.add(
                      RecurringOccurrenceLinked(
                        ruleId: rule.id,
                        date: date,
                        transactionId: raised.id,
                      ),
                    );
                  },
                ),
                AppButton.secondary(
                  small: true,
                  label: t.recurring.priceUpUpdate,
                  onPressed: () {
                    AppAnalytics.log(
                      RecurringEvents.priceIncreaseAction('update'),
                    );
                    bloc
                      ..add(
                        RecurringOccurrenceLinked(
                          ruleId: rule.id,
                          date: date,
                          transactionId: raised.id,
                        ),
                      )
                      ..add(
                        RecurringAmountUpdated(
                          ruleId: rule.id,
                          amount: raised.amount,
                        ),
                      );
                  },
                ),
              ] else if (unseen)
                AppButton.text(
                  small: true,
                  label: t.recurring.notYetAction,
                  onPressed: () =>
                      bloc.add(RecurringOccurrenceSnoozed(ruleId: rule.id)),
                )
              else if (fixed)
                AppButton.text(
                  small: true,
                  label: t.recurring.editFirstAction,
                  onPressed: () => _editFirst(context, date),
                ),
              if (raised == null)
                AppButton.secondary(
                  small: true,
                  label: t.recurring.recordAction,
                  onPressed: fixed
                      ? () => bloc.add(
                          RecurringOccurrenceRecorded(
                            ruleId: rule.id,
                            date: date,
                          ),
                        )
                      : () => _editFirst(context, date),
                ),
            ],
          ),
        ),
      ],
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
  final fixed = pending
      .where((e) => e.rule.amountMode == RecurringAmountMode.fixed)
      .length;
  if (fixed < 2) return null;
  return AppButton.secondary(
    label: t.recurring.recordAllAction,
    onPressed: () =>
        context.read<RecurringBloc>().add(const RecurringPendingRecordedAll()),
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
    super.key,
  });

  /// Kontainer akar.
  final GetIt container;

  /// Membuka segmen Rutin.
  final VoidCallback onShowAll;

  /// Tur dan langkah yang menyorot kartu ini, atau `null`. Hanya untuk satu
  /// tempat pemakaian (Beranda): kunci spotlight hanya boleh satu target.
  final ({TourId tour, SpotlightKey key})? spotlight;

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
                  if (state.isLoading || state.loadFailed) {
                    return const SizedBox.shrink();
                  }
                  final pending = pendingEntries(state);
                  if (pending.isEmpty) return const SizedBox.shrink();
                  final recordAll = recordAllButton(context, pending);
                  // Prototipe `BerandaRutin.dc.html`: judul bagian dengan tautan
                  // ke segmen Rutin, kartu daftar kemunculan menunggu.
                  final card = Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.space6),
                    child: SpotlightTarget(
                      spotlightKey: spotlight?.key,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSectionHeader(
                            '${t.recurring.pendingCardTitle} (${pending.length})',
                            actionLabel: t.recurring.seeAllAction,
                            onAction: onShowAll,
                          ),
                          const SizedBox(height: AppSpacing.space2),
                          AppListCard(
                            children: [
                              for (final entry in pending.take(_maxShown))
                                RecurringPendingTile(
                                  entry: entry,
                                  state: state,
                                ),
                            ],
                          ),
                          if (recordAll != null) ...[
                            const SizedBox(height: AppSpacing.space2),
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
