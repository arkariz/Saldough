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
import 'package:saldough/features/plan/presentation/widgets/balance_forecast_card.dart';
import 'package:saldough/features/plan/presentation/widgets/unplanned_card.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:state_management/state_management.dart';

/// Segmen **Bulan ini** tab Rencana (T-14.13, PLAN_TAB_LAYOUT §4, §4.9):
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
        const padding = EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.fabClearance);
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
              AppHardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.plan.emptyTitle, style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(t.plan.emptyBody, style: textTheme.bodySmall),
                    if (starters != null) ...[const SizedBox(height: AppSpacing.md), starters!],
                  ],
                ),
              ),
            ],
          );
        }
        final bloc = context.read<PlanMonthBloc>();
        final range = state.range;
        final monthLabel = range.start.day == 1 ? CycleMonthFormatter.formatMonthShort(range.start) : range.label;
        final next = state.nextOccurrences;
        return TourTrigger(
          tour: TourId.planMonth,
          ready: true,
          child: ListView(
            padding: padding,
            children: [
              SpotlightTarget(
                spotlightKey: SpotlightKey.planUnplanned,
                child: UnplannedCard(
                  plan: state.plan,
                  monthLabel: monthLabel,
                  onShowRecurring: onShowRecurring,
                  onShowBudget: onShowBudget,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
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
                ),
              ),
              ?pending,
              if (next.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
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
