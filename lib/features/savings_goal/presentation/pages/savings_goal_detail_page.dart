import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/features/savings_goal/presentation/bloc/savings_goal_bloc.dart';
import 'package:saldough/features/savings_goal/presentation/navigation/savings_goal_route_keys.dart';
import 'package:saldough/features/savings_goal/presentation/widgets/goal_estimate_section.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/features/wallet/presentation/navigation/wallet_route_keys.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/savings_goal/savings_goal_presentation.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:state_management/state_management.dart';

/// Banyaknya catatan terbaru di riwayat tujuan.
const _historyLimit = 20;

/// Rincian tujuan tabungan (rupa B-96 §3): kemajuan dari saldo dompet
/// tertaut, dompetnya, riwayat catatan di dompet itu, dan tindakan.
class SavingsGoalDetailPage extends StatelessWidget {
  /// Membuat [SavingsGoalDetailPage].
  const SavingsGoalDetailPage({required this.goalId, super.key});

  /// Tujuan yang ditampilkan.
  final String goalId;

  Future<void> _reactivate(BuildContext context, SavingsGoal goal, SavingsGoalState state) async {
    final bloc = context.read<SavingsGoalBloc>();
    final limit = ActivePlan.isPlus ? null : ActivePlan.limits.value.freeSavingsGoals;
    final progress = state.progressOf(goal);
    // Menjadi Active melewati batas Gratis membuka P11 (ADR-048 §3.5).
    if (limit != null && !progress.reached && activeGoalCount(state.goals, exceptId: goal.id) >= limit) {
      await context.pushRoute(PremiumRouteKeys.paywall, const PaywallInput(PaywallTrigger.savingsGoalLimit));
      return;
    }
    bloc.add(SavingsGoalReactivated(goal.id, activeLimit: limit));
  }

  Future<void> _delete(BuildContext context, SavingsGoal goal) async {
    final bloc = context.read<SavingsGoalBloc>();
    final confirmed = await showConfirmDelete(
      context,
      title: t.assets.goal.deleteConfirmTitle,
      message: t.assets.goal.deleteConfirmBodyAll,
    );
    if (confirmed) bloc.add(SavingsGoalDeleted(goal.id));
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return BlocListener<SavingsGoalBloc, SavingsGoalState>(
      // Hapus berhasil menutup rincian.
      listenWhen: (a, b) => a.saveCount != b.saveCount && b.goalById(goalId) == null,
      listener: (context, _) => Navigator.of(context).maybePop(),
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<SavingsGoalBloc, SavingsGoalState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    spacing: 16,
                    children: [
                      DsSkeleton(height: 48, radius: DsRadius.fullAll),
                      DsSkeleton(height: 200, radius: DsRadius.lgAll),
                    ],
                  ),
                );
              }
              final goal = state.goalById(goalId);
              if (goal == null) {
                return Center(child: Text(t.assets.goal.notFound, style: ds.typography.bodyMd));
              }
              final progress = state.progressOf(goal);
              final walletsById = {for (final w in state.wallets) w.id: w};
              final history = state.historyOf(goal).take(_historyLimit).toList();
              final active = goal.status == SavingsGoalStatus.active;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        DsIconButton(
                          icon: Icons.arrow_back,
                          label: t.transaction.detailBackLabel,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  DsCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        savingsGoalTile(goal.iconKey, size: DsIconTileSize.lg),
                        const SizedBox(height: 12),
                        Text(goal.name, textAlign: TextAlign.center, style: ds.typography.headlineSm),
                        const SizedBox(height: 8),
                        Text(
                          AppMoneyText.format(progress.collected, MoneyKind.balance),
                          style: ds.typography.displayLg.copyWith(fontSize: 30),
                        ),
                        Text(
                          t.assets.goal.progress(
                            saved: '${progress.percent}%',
                            target: AppMoneyText.format(progress.target, MoneyKind.balance),
                          ),
                          style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        DsSegmentMeter(value: progress.percent / 100, semanticLabel: '${progress.percent}%'),
                        const SizedBox(height: 12),
                        if (goal.status == SavingsGoalStatus.completed)
                          DsBadge(label: t.assets.goal.reached, tone: DsBadgeTone.income)
                        else
                          Text(
                            t.assets.goal.remaining(amount: AppMoneyText.format(progress.remaining, MoneyKind.balance)),
                            style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w700),
                          ),
                        if (goal.targetDate case final date?) ...[
                          const SizedBox(height: 4),
                          Text(
                            t.assets.goal.targetDate(date: CycleMonthFormatter.formatDate(date)),
                            style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                          ),
                        ],
                        if (goal.description case final description? when description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(description, textAlign: TextAlign.center, style: ds.typography.bodySm),
                        ],
                      ],
                    ),
                  ),
                  if (active && progress.remaining > 0) ...[
                    const SizedBox(height: 16),
                    if (ActivePlan.isPlus)
                      GoalEstimateSection(
                        estimate: state.estimateOf(
                          goal,
                          today: DateTime.now(),
                          schedule: ActiveFinancialMonth.schedule,
                        ),
                      )
                    else
                      GoalEstimateLocked(
                        onTap: () => context.pushRoute(
                          PremiumRouteKeys.paywall,
                          const PaywallInput(PaywallTrigger.goalEstimate),
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  if (state.walletOf(goal) case final wallet?)
                    DsButton.secondary(
                      key: const ValueKey('goal-view-wallet'),
                      label: t.assets.goal.viewWalletAction,
                      expand: true,
                      onPressed: () async {
                        final bloc = context.read<SavingsGoalBloc>();
                        await context.pushRoute(WalletRouteKeys.detail, WalletDetailInput(wallet));
                        bloc.add(const SavingsGoalStarted());
                      },
                    ),
                  const SizedBox(height: 16),
                  DsSectionHeader(title: t.assets.goal.detailHistory),
                  if (history.isEmpty)
                    Text(t.assets.goal.historyEmpty, style: ds.typography.bodySm.copyWith(color: c.textSecondary))
                  else
                    DsListCard(
                      children: [
                        for (final tx in history)
                          TransactionLedgerRow(
                            transaction: tx,
                            walletsById: walletsById,
                            onTap: () => context.pushRoute(TransactionRouteKeys.detail, TransactionDetailInput(tx)),
                          ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  DsButton(
                    label: t.assets.goal.editAction,
                    expand: true,
                    onPressed: () async {
                      final bloc = context.read<SavingsGoalBloc>();
                      await context.pushRoute(SavingsGoalRouteKeys.form, SavingsGoalFormInput(goal: goal));
                      // Formulir memakai lingkupnya sendiri; muat ulang sesudahnya.
                      bloc.add(const SavingsGoalStarted());
                    },
                  ),
                  const SizedBox(height: 8),
                  if (active)
                    DsButton.secondary(
                      label: t.assets.goal.archiveAction,
                      expand: true,
                      onPressed: () => context.read<SavingsGoalBloc>().add(SavingsGoalArchived(goal.id)),
                    )
                  else
                    DsButton.secondary(
                      label: t.assets.goal.reactivateAction,
                      expand: true,
                      onPressed: () => _reactivate(context, goal, state),
                    ),
                  const SizedBox(height: 8),
                  DsButton.danger(
                    label: t.assets.goal.deleteAction,
                    expand: true,
                    onPressed: () => _delete(context, goal),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
