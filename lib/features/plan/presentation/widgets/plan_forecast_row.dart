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

/// Baris perkiraan di Beranda (T-15.13, QA PR #43 F13): "Perkiraan saldo
/// 31 Okt ≈…" plus "Terendah ≈… pada 24 Okt" bila lebih rendah dari akhir
/// bulan ([PlanForecastSummary]). Disisipkan akar komposisi; tampil hanya
/// bila sudah ada rutin. Ketuk → Rencana › Bulan ini.
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
                          : PlanForecastSummary(
                              endDate: state.range.lastDay,
                              endBalance: projection.endBalance,
                              lowDate: low.date,
                              lowBalance: low.balance,
                              onTap: onTap,
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

/// Perkiraan saldo dompet akhir bulan dengan pola label–nilai kartu bulan
/// Beranda: "Perkiraan saldo 31 Okt" dan "≈Rp8.615.000" rata kanan, lalu
/// "Terendah ≈… pada 24 Okt" hanya bila titik terendah lebih rendah dari
/// akhir bulan (bernada bahaya bila di bawah nol). "Saldo" sah di sini:
/// isinya saldo dompet, bukan uang nganggur (ADR-035).
class PlanForecastSummary extends StatelessWidget {
  /// Membuat [PlanForecastSummary].
  const PlanForecastSummary({
    required this.endDate,
    required this.endBalance,
    required this.lowDate,
    required this.lowBalance,
    required this.onTap,
    super.key,
  });

  /// Hari terakhir bulan keuangan.
  final DateTime endDate;

  /// Perkiraan saldo di [endDate] (sen).
  final int endBalance;

  /// Hari saldo terendah.
  final DateTime lowDate;

  /// Perkiraan saldo terendah (sen).
  final int lowBalance;

  /// Membuka Rencana › Bulan ini.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final label = t.plan.forecastEndLabel(date: CycleMonthFormatter.formatDayMonth(endDate));
    final value = t.plan.approxAmount(amount: AppMoneyFormatter.formatApprox(endBalance));
    final showLow = lowBalance < endBalance;
    final lowText = t.plan.forecastLowest(
      amount: t.plan.approxAmount(amount: AppMoneyFormatter.formatApprox(lowBalance)),
      date: CycleMonthFormatter.formatDayMonth(lowDate),
    );
    return AppTappable(
      label: [label, value, if (showLow) lowText].join(', '),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            // Label selebar teksnya (paling lebar dua pertiga baris), nilai
            // mengisi sisanya dan diperkecil bila tetap tidak muat.
            builder: (context, constraints) => Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth * 2 / 3),
                  child: Text(label, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      value,
                      key: const ValueKey('forecast-end'),
                      style: context.numberStyles.amountSm.copyWith(color: endBalance < 0 ? colors.danger : colors.ink),
                    ),
                  ),
                ),
                AppIcon(IconKey.chevronRight, size: 18, color: colors.ink3),
              ],
            ),
          ),
          if (showLow)
            Text(
              lowText,
              key: const ValueKey('forecast-lowest'),
              style: textTheme.bodySmall?.copyWith(color: lowBalance < 0 ? colors.danger : colors.ink2),
            ),
        ],
      ),
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
              t.plan.reviewTitle(month: month),
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
