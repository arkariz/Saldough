import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_state.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_card.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_empty_states.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_filter_bar.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_form_sheet.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_summary_card.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Membuka formulir TAMBAH anggaran, lalu mengirim hasilnya ke `BudgetBloc`.
Future<void> addBudget(BuildContext context) async {
  final bloc = context.read<BudgetBloc>();
  final result = await showFullScreenSheet<BudgetFormResult>(
    context,
    builder: (_) => BudgetFormSheet(wallets: bloc.state.activeWallets),
  );
  if (result case BudgetFormSaved(
    :final name,
    :final walletId,
    :final period,
    :final startDate,
    :final plannedAmount,
    :final items,
  )) {
    bloc.add(
      BudgetAdded(
        name: name,
        walletId: walletId,
        period: period,
        startDate: startDate,
        plannedAmount: plannedAmount,
        items: items,
      ),
    );
  }
}

/// Membuka formulir SUNTING [budget] dan meneruskan hasilnya (simpan,
/// arsip, hapus) ke `BudgetBloc`. Mengembalikan hasil formulir supaya layar
/// rincian bisa menutup dirinya sesudah anggaran dihapus.
Future<BudgetFormResult?> editBudget(BuildContext context, Budget budget) async {
  final bloc = context.read<BudgetBloc>();
  final wallets = <Wallet>[
    ...bloc.state.activeWallets,
    // Dompet anggaran ini tetap jadi pilihan walau sudah dinonaktifkan.
    if (bloc.state.walletOf(budget.walletId) case final wallet? when !wallet.isActive) wallet,
  ];
  final result = await showFullScreenSheet<BudgetFormResult>(
    context,
    builder: (_) => BudgetFormSheet(wallets: wallets, initial: budget),
  );
  switch (result) {
    case BudgetFormSaved(
      :final name,
      :final walletId,
      :final period,
      :final startDate,
      :final plannedAmount,
      :final items,
    ):
      bloc.add(
        BudgetEdited(
          budget.copyWith(
            name: name,
            walletId: walletId,
            period: period,
            startDate: startDate,
            plannedAmount: plannedAmount,
            items: items,
          ),
        ),
      );
    case BudgetFormArchiveToggled():
      bloc.add(BudgetArchiveToggled(budget));
    case BudgetFormDeleted():
      bloc.add(BudgetDeleted(budget));
    case null:
      break;
  }
  return result;
}

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
  /// Membuat [BudgetListPage]. [onOpenBudget] dipanggil saat kartu diketuk.
  const BudgetListPage({this.onOpenBudget, super.key});

  /// Membuka rincian anggaran; bawaan membuka formulir sunting.
  final void Function(BuildContext context, Budget budget)? onOpenBudget;

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
                      onTap: () => (widget.onOpenBudget ?? editBudget)(context, budget),
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
