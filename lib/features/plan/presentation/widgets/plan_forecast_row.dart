import 'package:di/di.dart';
import 'package:flutter/material.dart';
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
import 'package:saldough/features/plan/presentation/widgets/funding_banner.dart';
import 'package:state_management/state_management.dart';

/// Baris perkiraan di Beranda (T-15.13): "Akhir Okt ≈… · paling tipis ≈…".
/// Disisipkan akar komposisi; tampil hanya bila sudah ada rutin. Ketuk →
/// Rencana › Bulan ini.
class PlanForecastRow extends StatelessWidget {
  /// Membuat [PlanForecastRow].
  const PlanForecastRow({
    required this.container,
    required this.onTap,
    super.key,
  });

  /// Kontainer akar.
  final GetIt container;

  /// Membuka Rencana › Bulan ini.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScopeWidget<PlanScope>(
      create: () => PlanScope(parentContainer: container),
      builder: (context, scope) {
        final bloc = scope.container<PlanMonthBloc>();
        return BlocProvider.value(
          value: bloc,
          child: RunOnce(
            action: () => bloc.add(const PlanMonthLoaded()),
            child: BlocBuilder<PlanMonthBloc, PlanMonthState>(
              builder: (context, state) {
                if (state.isLoading || state.loadFailed) return const SizedBox.shrink();
                // Kartu sekali tampil "Oktober dimulai" (J4, ADR-036 §3.7).
                final review = state.showReview && !state.review.dismissed
                    ? _MonthStartCard(state: state, onReview: onTap)
                    : null;
                if (state.rules.isEmpty) return review ?? const SizedBox.shrink();
                final projection = state.projection;
                final low = projection.lowest;
                if (low == null) return const SizedBox.shrink();
                final colors = context.appColors;
                final funding = state.fundingWarnings;
                // Muncul belakangan dari Beranda: picu tur Beranda lagi.
                final row = TourTrigger(
                  tour: TourId.home,
                  ready: true,
                  child: SpotlightTarget(
                    spotlightKey: SpotlightKey.homeForecast,
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.space4),
                      // Wawasan prioritas 1 di Beranda (§7B W1): siapkan dana.
                      child: funding.isNotEmpty
                          ? FundingBanner(
                              warnings: funding,
                              onShowWallet: (_) => onTap(),
                            )
                          : AppTappable(
                              label: t.plan.balanceTitle,
                              onTap: onTap,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.plan.forecastRow(
                                        date: CycleMonthFormatter.formatDayMonth(
                                          state.range.lastDay,
                                        ),
                                        amount: AppMoneyFormatter.formatApprox(
                                          projection.endBalance,
                                        ),
                                        low: AppMoneyFormatter.formatApprox(
                                          low.balance,
                                        ),
                                        lowDate: CycleMonthFormatter.formatDayMonth(
                                          low.date,
                                        ),
                                      ),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: low.balance < 0 ? colors.danger : colors.ink2,
                                      ),
                                    ),
                                  ),
                                  const AppIcon(IconKey.chevronRight, size: 18),
                                ],
                              ),
                            ),
                    ),
                  ),
                );
                return review == null ? row : Column(children: [review, row]);
              },
            ),
          ),
        );
      },
    );
  }
}

/// Kartu Beranda "Oktober dimulai" (J4): pemasukan terjadwal, yang terikat,
/// dan uang nganggur, plus satu baris bila ada rutin kira-kira.
class _MonthStartCard extends StatelessWidget {
  const _MonthStartCard({required this.state, required this.onReview});

  final PlanMonthState state;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final plan = state.planFor(0);
    final month = state.range.start.day == 1
        ? CycleMonthFormatter.formatMonthShort(state.range.start)
        : state.range.label;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space4),
      child: AppCard(
        key: const ValueKey('home-month-start'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.plan.reviewTitle(month: month).toUpperCase(),
              style: labelSmStyle(context, color: colors.ink2),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              t.plan.homeReviewBody(
                income: AppMoneyFormatter.format(plan.plannedIncome),
                committed: AppMoneyFormatter.format(
                  plan.plannedRecurringOut + plan.budgetPlanned,
                ),
                free: AppMoneyFormatter.format(plan.planned),
              ),
              style: textTheme.bodyMedium,
            ),
            if (state.estimatedRules.isNotEmpty)
              Text(
                t.plan.homeReviewEstimates,
                style: textTheme.bodySmall?.copyWith(color: colors.ink2),
              ),
            Wrap(
              children: [
                AppButton.text(
                  small: true,
                  label: t.plan.homeReviewAction,
                  onPressed: onReview,
                ),
                AppButton.text(
                  small: true,
                  label: t.plan.reviewLater,
                  onPressed: () => context.read<PlanMonthBloc>().add(
                    const PlanReviewDismissed(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
