import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/budget/presentation/navigation/budget_route_keys.dart';
import 'package:saldough/features/plan/di/plan_scope.dart';
import 'package:saldough/features/plan/presentation/bloc/plan_month_bloc.dart';
import 'package:saldough/features/plan/presentation/bloc/plan_month_state.dart';
import 'package:saldough/features/plan/presentation/widgets/balance_forecast_card.dart';
import 'package:saldough/features/plan/presentation/widgets/funding_banner.dart';
import 'package:saldough/features/plan/presentation/widgets/month_review_card.dart';
import 'package:saldough/features/plan/presentation/widgets/payday_offer_card.dart';
import 'package:saldough/features/plan/presentation/widgets/plan_distribution.dart';
import 'package:saldough/features/plan/presentation/widgets/plan_indicators.dart';
import 'package:saldough/features/plan/presentation/widgets/unplanned_card.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:state_management/state_management.dart';

/// Segmen **Bulan ini** tab Rencana (T-15.13, PLAN_TAB_LAYOUT §4, §4.9):
/// kartu Uang nganggur, kartu Saldo dompet ≈, Menunggu + tiga berikutnya,
/// atau keadaan kosong. Isi dari fitur lain (kartu Menunggu, chip pembuka)
/// disisipkan akar komposisi lewat [pending] dan [starters], jadi `plan`
/// tidak mengimpor `recurring`.
class PlanMonthPage extends StatelessWidget {
  /// Membuat [PlanMonthPage].
  const PlanMonthPage({
    required this.container,
    required this.onShowRecurring,
    required this.onShowBudget,
    this.pending,
    this.starters,
    super.key,
  });

  /// Kontainer akar.
  final GetIt container;

  /// Ke segmen Rutin.
  final VoidCallback onShowRecurring;

  /// Ke segmen Anggaran.
  final VoidCallback onShowBudget;

  /// Kartu Menunggu dicatat (tampil hanya bila ada isinya).
  final Widget? pending;

  /// Chip pembuka rutin untuk keadaan kosong.
  final Widget? starters;

  @override
  Widget build(BuildContext context) {
    return ScopeWidget<PlanScope>(
      create: () => PlanScope(parentContainer: container),
      builder: (context, scope) {
        final bloc = scope.container<PlanMonthBloc>();
        return BlocProvider.value(
          value: bloc,
          child: EffectListener<PlanMonthBloc, PlanMonthState>(
            child: RunOnce(
              action: () => bloc.add(const PlanMonthLoaded()),
              child: PlanMonthView(
                onShowRecurring: onShowRecurring,
                onShowBudget: onShowBudget,
                paydayOffer: PaydayOfferCard(container: container),
                pending: pending,
                starters: starters,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Isi segmen Bulan ini di atas `PlanMonthBloc` yang sudah terpasang.
class PlanMonthView extends StatelessWidget {
  /// Membuat [PlanMonthView].
  const PlanMonthView({
    required this.onShowRecurring,
    required this.onShowBudget,
    this.paydayOffer,
    this.pending,
    this.starters,
    super.key,
  });

  /// Ke segmen Rutin.
  final VoidCallback onShowRecurring;

  /// Ke segmen Anggaran.
  final VoidCallback onShowBudget;

  /// Kartu tawaran gajian (FEATURE_DISCOVERY §6.2), di bawah kepala periode.
  final Widget? paydayOffer;

  /// Kartu Menunggu dicatat.
  final Widget? pending;

  /// Chip pembuka rutin.
  final Widget? starters;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlanMonthBloc, PlanMonthState>(
      builder: (context, state) {
        if (state.isLoading) return const AppSkeletonPage();
        const padding = EdgeInsets.fromLTRB(16, 16, 16, 96);
        if (state.loadFailed) {
          return DsErrorState(
            title: t.plan.loadError,
            retryLabel: t.recurring.retryAction,
            onRetry: () => context.read<PlanMonthBloc>().add(const PlanMonthLoaded()),
          );
        }
        final ds = context.ds;
        if (state.isEmpty) {
          return ListView(
            padding: padding,
            children: [
              DsReveal(
                child: DsCard(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    children: [
                      const DsEmptyHero(
                        asset: ClayIcons.dateCalendar,
                        orbit: [ClayIcons.coins, ClayIcons.repeat, ClayIcons.chart],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.plan.emptyTitle,
                        textAlign: TextAlign.center,
                        style: ds.typography.titleMd.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.plan.emptyBody,
                        textAlign: TextAlign.center,
                        style: ds.typography.bodySm.copyWith(color: ds.colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ?starters,
            ],
          );
        }
        final bloc = context.read<PlanMonthBloc>();
        final range = state.selectedRange;
        // Nama bulan hanya untuk periode biasa yang mulai tanggal 1; periode
        // peralihan selalu rentang (P-11).
        String labelOf(FinancialPeriod m) => m.shortName;
        final monthLabel = labelOf(range);
        final next = state.nextOccurrences;
        final funding = state.fundingWarnings;
        final committed = state.committedShareFor(state.selected);
        final installmentFree = nearestInstallmentFree(state.rules, today: state.today);
        final mutedSmall = ds.typography.bodySm.copyWith(color: ds.colors.textSecondary);
        return TourTrigger(
          tour: TourId.planMonth,
          ready: true,
          child: ListView(
            padding: padding,
            children: [
              // Kepala periode (PeriodHeader, FINANCIAL_PERIOD F1, P-11): nama
              // periode terpilih, pintu ke lembar Awal bulan keuangan.
              SpotlightTarget(
                spotlightKey: SpotlightKey.planPeriodHeader,
                child: AppPeriodHeader(
                  label: range.name,
                  transitionDays: range.isTransition ? range.days : null,
                  onTap: () => unawaited(
                    context.pushRoute(
                      BudgetRouteKeys.financialMonth,
                      const FinancialMonthInput(source: FinancialMonthSource.plan),
                    ),
                  ),
                  // Tur peralihan hanya untuk periode berjalan (FINANCIAL_PERIOD §8A).
                  wrapTag: (tag) => SpotlightTarget(
                    spotlightKey: state.selected == 0 ? SpotlightKey.planTransition : null,
                    child: tag,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tawaran gajian untuk pengguna lama (FEATURE_DISCOVERY §6.2).
              ?paydayOffer,
              // Blok 0: tinjau awal bulan (J4, ADR-036 §3.7).
              if (state.showReview && !state.isFuture) ...[
                DsScrollReveal(
                  child: MonthReviewCard(
                    state: state,
                    monthLabel: labelOf(state.range),
                    onShowBudget: onShowBudget,
                    onShowRecurring: onShowRecurring,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Blok 0: siapkan dana (W1, ADR-036 §3.6).
              if (funding.isNotEmpty) ...[
                DsScrollReveal(
                  child: FundingBanner(
                    warnings: funding,
                    onShowWallet: (walletId) => bloc
                      ..add(const PlanMonthSelected(0))
                      ..add(PlanMonthWalletChanged(walletId)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Pemilih bulan (PLAN_TAB_LAYOUT §4.3): bulan berjalan + 2,
              // tiap chip membawa perkiraan akhir bulannya.
              SpotlightTarget(
                spotlightKey: SpotlightKey.planMonthPicker,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (k, m) in state.months.indexed) ...[
                        if (k > 0) const SizedBox(width: 8),
                        DsFilterChip(
                          key: ValueKey('plan-month-$k'),
                          // Bulan keuangan 25 Okt–24 Nov disebut "Nov" (T-16.16 K8).
                          label:
                              '${CycleMonthFormatter.formatMonthShort(m.lastDay)} '
                              '${compactApprox(state.projectionFor(k).endBalance)}',
                          selected: state.selected == k,
                          onTap: () => bloc.add(PlanMonthSelected(k)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SpotlightTarget(
                spotlightKey: SpotlightKey.planUnplanned,
                child: DsScrollReveal(
                  child: UnplannedCard(
                    plan: state.plan,
                    isForecast: state.isFuture,
                    withoutPayday: state.transitionWithoutPayday,
                    monthLabel: monthLabel,
                    onShowRecurring: onShowRecurring,
                    onShowBudget: onShowBudget,
                  ),
                ),
              ),
              // Wawasan teks netral (W8, W7, ADR-036 §3.7).
              if (committed != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    committed.previous == null
                        ? t.plan.committedShare(percent: committed.share, month: monthLabel)
                        : t.plan.committedShareVs(
                            percent: committed.share,
                            month: monthLabel,
                            previous: committed.previous!,
                          ),
                    key: const ValueKey('plan-committed-share'),
                    style: mutedSmall,
                  ),
                ),
              if (installmentFree != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    t.plan.installmentFree(
                      name: installmentFree.rule.note.isEmpty
                          ? t.record.repeat.fallbackName
                          : installmentFree.rule.note,
                      month: CycleMonthFormatter.formatMonthYearShort(installmentFree.from),
                      amount: AppMoneyFormatter.format(installmentFree.perMonth),
                    ),
                    key: const ValueKey('plan-installment-free'),
                    style: mutedSmall,
                  ),
                ),
              const SizedBox(height: 20),
              DsScrollReveal(
                child: PlanIndicators(
                  plan: state.plan,
                  lowest: state.projection.lowest,
                  committedShare: committed?.share,
                  previousShare: committed?.previous,
                  unplannedPerDay: state.unplannedAverage,
                ),
              ),
              const SizedBox(height: 20),
              SpotlightTarget(
                spotlightKey: SpotlightKey.planForecast,
                child: DsScrollReveal(
                  child: BalanceForecastCard(
                    projection: state.projection,
                    lastDay: range.lastDay,
                    wallets: state.wallets,
                    walletId: state.walletId,
                    onWalletChanged: (id) => bloc.add(PlanMonthWalletChanged(id)),
                    unplannedAvailable: state.unplannedAverage != null,
                    includeUnplanned: state.includeUnplanned,
                    onUnplannedToggled: (value) => bloc.add(PlanMonthUnplannedToggled(enabled: value)),
                    isFuture: state.isFuture,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              DsScrollReveal(
                child: PlanDistribution(plan: state.plan),
              ),
              if (!state.isFuture && pending != null) ...[const SizedBox(height: 4), DsScrollReveal(child: pending!)],
              const SizedBox(height: 24),
              DsSectionHeader(title: t.plan.nextTitle, actionLabel: t.plan.seeAllRecurring, onAction: onShowRecurring),
              if (next.isNotEmpty) ...[
                const SizedBox(height: 8),
                DsListCard(
                  children: [
                    for (final (i, o) in next.indexed)
                      DsReveal(
                        index: i,
                        child: _NextRow(occurrence: o),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Nominal ringkas berawalan `≈` untuk chip bulan: "≈10,9 jt", "≈850 rb".
/// Pembulatan hanya untuk tampilan.
String compactApprox(int sen) {
  final units = (sen.abs() + 50) ~/ 100;
  final sign = sen < 0 ? '−' : '';
  if (units >= 1000000) {
    final tenths = (units + 50000) ~/ 100000;
    final value = tenths % 10 == 0 ? '${tenths ~/ 10}' : '${tenths ~/ 10}${MoneySeparators.decimal}${tenths % 10}';
    return '≈$sign${t.plan.compactMillion(value: value)}';
  }
  return '≈$sign${t.plan.compactThousand(value: (units + 500) ~/ 1000)}';
}

class _NextRow extends StatelessWidget {
  const _NextRow({required this.occurrence});

  final Occurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final rule = occurrence.rule;
    final sign = switch (rule.kind) {
      RecurringKind.income => '+',
      RecurringKind.expense => '−',
      RecurringKind.transfer => '',
    };
    final approx = rule.amountMode == RecurringAmountMode.estimated ? '≈' : '';
    final date = occurrence.date;
    // Baris jadwal: kotak tanggal, nama, nominal bertanda.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                      Text('${date.day}', style: ds.typography.amount.copyWith(fontSize: 17, height: 20 / 17)),
                      Text(
                        CycleMonthFormatter.formatWeekday(date).substring(0, 3),
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
                rule.note.isEmpty ? t.record.repeat.fallbackName : rule.note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ds.typography.titleMd,
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  '$approx$sign${AppMoneyFormatter.format(rule.amount)}',
                  style: ds.typography.amount.copyWith(
                    color: switch (rule.kind) {
                      RecurringKind.income => c.income,
                      RecurringKind.expense => c.textPrimary,
                      RecurringKind.transfer => c.textSecondary,
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
