import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_state.dart';
import 'package:saldough/features/budget/presentation/budget_actions.dart';
import 'package:saldough/features/budget/presentation/pages/budget_detail_page.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_card.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_empty_states.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_filter_bar.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_summary_card.dart';
import 'package:state_management/state_management.dart';

/// Layar Anggaran (T-4.5/T-4.9; FR-BUD-001/004/006): ringkasan lintas
/// anggaran aktif, penyaring status dan dompet, lalu daftar kartu anggaran.
///
/// ⚠ Ini DAFTAR seluruh anggaran, bukan papan satu anggaran. Beberapa
/// anggaran boleh aktif sekaligus, berbagi dompet, dan berbeda periode.
///
/// `BudgetBloc` dipasang di level shell, sama seperti `WalletBloc`, karena
/// tab persisten selama shell hidup; progres disegarkan tiap tab ini dibuka
/// dan sesudah alur CATAT (lihat `AppShellPage`).
class BudgetListPage extends StatefulWidget {
  /// Membuat [BudgetListPage].
  const BudgetListPage({super.key});

  @override
  State<BudgetListPage> createState() => _BudgetListPageState();
}

class _BudgetListPageState extends State<BudgetListPage> {
  @override
  void initState() {
    super.initState();
    context.read<BudgetBloc>().add(const BudgetStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.appShell.budgetTabLabel)),
      body: SafeArea(
        child: BlocBuilder<BudgetBloc, BudgetState>(
          builder: (context, state) {
            if (state.isLoading) return const AppSkeletonPage();
            if (state.loadFailed) {
              return BudgetLoadErrorState(onRetry: () => context.read<BudgetBloc>().add(const BudgetStarted()));
            }
            final canAdd = state.activeWallets.isNotEmpty;
            if (state.budgets.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [BudgetEmptyState(onAdd: canAdd ? () => addBudget(context) : null)],
              );
            }

            final bloc = context.read<BudgetBloc>();
            final visible = state.visibleBudgets;
            final usedWalletIds = {for (final budget in state.budgets) budget.walletId};
            final filterWallets = state.wallets.where((w) => usedWalletIds.contains(w.id)).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
              children: [
                BudgetSummaryCard(
                  planned: state.activePlanned,
                  spent: state.activeSpent,
                  activeCount: state.activeProgress.length,
                ),
                const SizedBox(height: AppSpacing.md),
                BudgetFilterBar(
                  statusFilter: state.statusFilter,
                  statusCounts: state.statusCounts,
                  wallets: filterWallets,
                  walletFilter: state.walletFilter,
                  onStatusChanged: (filter) => bloc.add(BudgetStatusFilterChanged(filter)),
                  onWalletChanged: (walletId) => bloc.add(BudgetWalletFilterChanged(walletId)),
                ),
                const SizedBox(height: AppSpacing.md),
                if (visible.isEmpty)
                  BudgetFilteredEmptyState(
                    onReset: () => bloc
                      ..add(const BudgetStatusFilterChanged(BudgetStatusFilter.all))
                      ..add(const BudgetWalletFilterChanged(null)),
                  )
                else
                  for (final budget in visible) ...[
                    BudgetCard(
                      budget: budget,
                      progress: state.progress[budget.id]!,
                      walletName: state.walletOf(budget.walletId)?.name ?? t.budget.unknownWallet,
                      onTap: () => openBudgetDetail(context, budget),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                const SizedBox(height: AppSpacing.xs),
                if (canAdd) AppButton(label: t.budget.addAction, onPressed: () => addBudget(context)),
              ],
            );
          },
        ),
      ),
    );
  }
}
