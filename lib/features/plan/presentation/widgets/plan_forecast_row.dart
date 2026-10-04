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
import 'package:state_management/state_management.dart';

/// Baris perkiraan di Beranda (T-15.13): "Akhir Okt ≈… · paling tipis ≈…".
/// Disisipkan akar komposisi; tampil hanya bila sudah ada rutin. Ketuk →
/// Rencana › Bulan ini.
class PlanForecastRow extends StatelessWidget {
  /// Membuat [PlanForecastRow].
  const PlanForecastRow({required this.container, required this.onTap, super.key});

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
                if (state.isLoading || state.loadFailed || state.rules.isEmpty) return const SizedBox.shrink();
                final projection = state.projection;
                final low = projection.lowest;
                if (low == null) return const SizedBox.shrink();
                final colors = context.appColors;
                // Muncul belakangan dari Beranda: picu tur Beranda lagi.
                return TourTrigger(
                  tour: TourId.home,
                  ready: true,
                  child: SpotlightTarget(
                    spotlightKey: SpotlightKey.homeForecast,
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: AppTappable(
                        label: t.plan.balanceTitle,
                        onTap: onTap,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.plan.forecastRow(
                                  date: CycleMonthFormatter.formatDayMonth(state.range.lastDay),
                                  amount: AppMoneyFormatter.format(projection.endBalance),
                                  low: AppMoneyFormatter.format(low.balance),
                                  lowDate: CycleMonthFormatter.formatDayMonth(low.date),
                                ),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: low.balance < 0 ? colors.overBudget : colors.textMuted,
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
              },
            ),
          ),
        );
      },
    );
  }
}
