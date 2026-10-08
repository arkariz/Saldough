import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_state.dart';
import 'package:saldough/features/budget/presentation/budget_actions.dart';
import 'package:saldough/features/budget/presentation/navigation/budget_route_keys.dart';
import 'package:saldough/features/budget/presentation/pages/budget_template_page.dart';
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
  const BudgetListPage({this.embedded = false, super.key});

  /// Segmen Anggaran di tab Rencana (T-15.4): tanpa app bar sendiri, karena
  /// judulnya mengikuti app bar Rencana (PLAN_TAB_LAYOUT §5).
  final bool embedded;

  @override
  State<BudgetListPage> createState() => _BudgetListPageState();
}

class _BudgetListPageState extends State<BudgetListPage> {
  @override
  void initState() {
    super.initState();
    context.read<BudgetBloc>().add(const BudgetStarted());
  }

  /// Rincian memakai `BudgetBloc` miliknya sendiri (ADR-030 §3.3), jadi
  /// daftar ini disegarkan sesudah rinciannya ditutup (sunting, arsip,
  /// hapus).
  Future<void> _openDetail(BuildContext context, String budgetId) async {
    final bloc = context.read<BudgetBloc>();
    await context.pushRoute(BudgetRouteKeys.detail, BudgetDetailInput(budgetId: budgetId));
    bloc.add(const BudgetRefreshed());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: Text(t.appShell.budgetTabLabel)),
      body: SafeArea(
        top: !widget.embedded,
        child: BlocBuilder<BudgetBloc, BudgetState>(
          builder: (context, state) {
            if (state.isLoading) return const AppSkeletonPage();
            if (state.loadFailed) {
              return BudgetLoadErrorState(onRetry: () => context.read<BudgetBloc>().add(const BudgetStarted()));
            }
            final canAdd = state.activeWallets.isNotEmpty;
            if (state.budgets.isEmpty) {
              // TR-BUDGET: di keadaan kosong hanya Template yang tampil;
              // ringkasan dan penyaring disorot sendiri begitu ada anggaran.
              return TourTrigger(
                tour: TourId.budget,
                ready: true,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  children: [
                    BudgetEmptyState(onAdd: canAdd ? () => addBudget(context) : null),
                    const SizedBox(height: AppSpacing.space4),
                    SpotlightTarget(
                      spotlightKey: SpotlightKey.budgetTemplates,
                      child: _TemplatesButton(onTap: () => openBudgetTemplates(context)),
                    ),
                  ],
                ),
              );
            }

            final bloc = context.read<BudgetBloc>();
            final visible = state.visibleBudgets;
            final usedWalletIds = {for (final budget in state.budgets) budget.walletId};
            final filterWallets = state.wallets.where((w) => usedWalletIds.contains(w.id)).toList();
            return TourTrigger(
              tour: TourId.budget,
              ready: true,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space4,
                  AppSpacing.space2,
                  AppSpacing.space4,
                  AppSpacing.space12,
                ),
                children: [
                  SpotlightTarget(
                    spotlightKey: SpotlightKey.budgetSummary,
                    child: BudgetSummaryCard(
                      planned: state.activePlanned,
                      spent: state.activeSpent,
                      activeCount: state.activeProgress.length,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  SpotlightTarget(
                    spotlightKey: SpotlightKey.budgetFilter,
                    child: BudgetFilterBar(
                      statusFilter: state.statusFilter,
                      statusCounts: state.statusCounts,
                      wallets: filterWallets,
                      walletFilter: state.walletFilter,
                      onStatusChanged: (filter) => bloc.add(BudgetStatusFilterChanged(filter)),
                      onWalletChanged: (walletId) => bloc.add(BudgetWalletFilterChanged(walletId)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  if (visible.isEmpty)
                    BudgetFilteredEmptyState(
                      onReset: () => bloc
                        ..add(const BudgetStatusFilterChanged(BudgetStatusFilter.all))
                        ..add(const BudgetWalletFilterChanged(null)),
                    )
                  else
                    for (final budget in visible) ...[
                      const SizedBox(height: AppSpacing.space1),
                      BudgetCard(
                        budget: budget,
                        progress: state.progress[budget.id]!,
                        walletName: state.walletOf(budget.walletId)?.name ?? t.budget.unknownWallet,
                        onTap: () => _openDetail(context, budget.id),
                        isRecurring: state.isRecurring(budget),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                    ],
                  const SizedBox(height: AppSpacing.space2),
                  if (canAdd)
                    AppButton.secondary(
                      label: t.budget.addAction,
                      icon: IconKey.add,
                      expand: true,
                      onPressed: () => addBudget(context),
                    ),
                  SpotlightTarget(
                    spotlightKey: SpotlightKey.budgetTemplates,
                    child: _TemplatesButton(onTap: () => openBudgetTemplates(context)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Jalan ke layar Template Anggaran (T-7.2) — tombol teks di bawah "Buat
/// anggaran" (prototipe `RencanaAnggaran.dc.html`).
class _TemplatesButton extends StatelessWidget {
  const _TemplatesButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(child: AppButton.text(label: t.budget.templatesAction, onPressed: onTap));
  }
}
