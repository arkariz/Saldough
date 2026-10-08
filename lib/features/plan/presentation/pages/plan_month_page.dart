import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/plan/di/plan_scope.dart';
import 'package:saldough/features/plan/presentation/bloc/plan_month_bloc.dart';
import 'package:saldough/features/plan/presentation/bloc/plan_month_state.dart';
import 'package:saldough/features/plan/presentation/widgets/balance_forecast_card.dart';
import 'package:saldough/features/plan/presentation/widgets/funding_banner.dart';
import 'package:saldough/features/plan/presentation/widgets/month_review_card.dart';
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
    this.pending,
    this.starters,
    super.key,
  });

  /// Ke segmen Rutin.
  final VoidCallback onShowRecurring;

  /// Ke segmen Anggaran.
  final VoidCallback onShowBudget;

  /// Kartu Menunggu dicatat.
  final Widget? pending;

  /// Chip pembuka rutin.
  final Widget? starters;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlanMonthBloc, PlanMonthState>(
      builder: (context, state) {
        if (state.isLoading) return const AppSkeletonPage();
        const padding = EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, AppSpacing.space12);
        if (state.loadFailed) {
          return ListView(
            padding: padding,
            children: [
              Text(t.plan.loadError),
              AppButton(
                label: t.recurring.retryAction,
                onPressed: () => context.read<PlanMonthBloc>().add(const PlanMonthLoaded()),
              ),
            ],
          );
        }
        final textTheme = Theme.of(context).textTheme;
        if (state.isEmpty) {
          return ListView(
            padding: padding,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.plan.emptyTitle, style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.space1),
                    Text(t.plan.emptyBody, style: textTheme.bodySmall),
                    if (starters != null) ...[const SizedBox(height: AppSpacing.space4), starters!],
                  ],
                ),
              ),
            ],
          );
        }
        final bloc = context.read<PlanMonthBloc>();
        final range = state.selectedRange;
        String labelOf(FinancialMonthRange m) =>
            m.start.day == 1 ? CycleMonthFormatter.formatMonthShort(m.start) : m.label;
        final monthLabel = labelOf(range);
        final next = state.nextOccurrences;
        final funding = state.fundingWarnings;
        final committed = state.committedShareFor(state.selected);
        final installmentFree = nearestInstallmentFree(state.rules, today: state.today);
        final mutedSmall = textTheme.bodySmall?.copyWith(color: context.appColors.ink2);
        return TourTrigger(
          tour: TourId.planMonth,
          ready: true,
          child: ListView(
            padding: padding,
            children: [
              // Blok 0: tinjau awal bulan (J4, ADR-036 §3.7).
              if (state.showReview && !state.isFuture) ...[
                MonthReviewCard(
                  state: state,
                  monthLabel: labelOf(state.range),
                  onShowBudget: onShowBudget,
                  onShowRecurring: onShowRecurring,
                ),
                const SizedBox(height: AppSpacing.space4),
              ],
              // Blok 0: siapkan dana (W1, ADR-036 §3.6).
              if (funding.isNotEmpty) ...[
                FundingBanner(
                  warnings: funding,
                  onShowWallet: (walletId) => bloc
                    ..add(const PlanMonthSelected(0))
                    ..add(PlanMonthWalletChanged(walletId)),
                ),
                const SizedBox(height: AppSpacing.space4),
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
                        if (k > 0) const SizedBox(width: AppSpacing.space1),
                        AppChip(
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
              const SizedBox(height: AppSpacing.space4),
              SpotlightTarget(
                spotlightKey: SpotlightKey.planUnplanned,
                child: UnplannedCard(
                  plan: state.plan,
                  isForecast: state.isFuture,
                  monthLabel: monthLabel,
                  onShowRecurring: onShowRecurring,
                  onShowBudget: onShowBudget,
                ),
              ),
              // Wawasan teks netral (W8, W7, ADR-036 §3.7).
              if (committed != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.space2),
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
                  padding: const EdgeInsets.only(top: AppSpacing.space1),
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
              const SizedBox(height: AppSpacing.space4),
              SpotlightTarget(
                spotlightKey: SpotlightKey.planForecast,
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
              if (!state.isFuture) ?pending,
              if (next.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space4),
                AppSectionLabel(t.plan.nextTitle),
                for (final o in next) _NextRow(occurrence: o),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: onShowRecurring, child: Text('${t.plan.seeAllRecurring} ›')),
              ),
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
    final textTheme = Theme.of(context).textTheme;
    final rule = occurrence.rule;
    final sign = switch (rule.kind) {
      RecurringKind.income => '+',
      RecurringKind.expense => '−',
      RecurringKind.transfer => '⇄',
    };
    final approx = rule.amountMode == RecurringAmountMode.estimated ? '≈' : '';
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(CycleMonthFormatter.formatDayMonth(occurrence.date), style: textTheme.bodySmall),
          ),
          Expanded(
            child: Text(rule.note.isEmpty ? t.record.repeat.fallbackName : rule.note, style: textTheme.bodyMedium),
          ),
          Text('$approx$sign${AppMoneyFormatter.format(rule.amount)}', style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
