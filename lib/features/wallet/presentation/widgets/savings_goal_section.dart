import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/features/savings_goal/presentation/navigation/savings_goal_route_keys.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/savings_goal/savings_goal_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Bagian Tujuan di tab Dompet (rupa B-96 §1, ADR-048 §3.8): kartu tujuan
/// Active dan Completed, lalu yang diarsipkan; layar tujuan dibuka lewat kunci
/// rute dan tab dimuat ulang sesudahnya.
class SavingsGoalSection extends StatelessWidget {
  /// Membuat [SavingsGoalSection].
  const SavingsGoalSection({required this.goals, required this.wallets, super.key});

  /// Semua tujuan.
  final List<SavingsGoal> goals;

  /// Semua dompet, untuk kemajuan.
  final List<Wallet> wallets;

  Future<void> _open<T extends RouteInput>(BuildContext context, RouteKey<T> key, T input) async {
    final bloc = context.read<WalletBloc>();
    await context.pushRoute(key, input);
    bloc.add(const WalletRefreshed());
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final shown = goals.where((g) => g.status != SavingsGoalStatus.archived).toList();
    final archived = goals.where((g) => g.status == SavingsGoalStatus.archived).toList();
    Widget card(SavingsGoal goal) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SavingsGoalCard(
        key: ValueKey('goal-card-${goal.id}'),
        goal: goal,
        progress: SavingsGoalProgress.of(goal, wallets),
        onTap: () => _open(context, SavingsGoalRouteKeys.detail, SavingsGoalDetailInput(goal.id)),
      ),
    );
    void create() => _open(context, SavingsGoalRouteKeys.form, const SavingsGoalFormInput());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Isi segmen Tabungan (ADR-050 §3.3): tiap tujuan dengan dompetnya.
        SpotlightTarget(
          spotlightKey: SpotlightKey.walletGoals,
          child: DsSectionHeader(title: t.assets.goal.title, actionLabel: t.assets.goal.create, onAction: create),
        ),
        const SizedBox(height: 8),
        if (goals.isEmpty)
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const DsIconTile(icon: Symbols.savings_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.assets.goal.emptyBody,
                        style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DsButton.secondary(
                  key: const ValueKey('goal-create-empty'),
                  label: t.assets.goal.create,
                  onPressed: create,
                ),
              ],
            ),
          ),
        for (final goal in shown) card(goal),
        if (archived.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(t.assets.goal.archivedHeading, style: ds.typography.labelMd.copyWith(color: ds.colors.textMuted)),
          const SizedBox(height: 8),
          for (final goal in archived) card(goal),
        ],
      ],
    );
  }
}
