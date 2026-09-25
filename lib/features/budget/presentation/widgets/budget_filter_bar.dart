import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_state.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Penyaring layar Anggaran (FR-BUD-006): empat status dalam satu baris tab,
/// lalu satu pilihan dompet. Sengaja sederhana — daftar dan pilihan, bukan
/// antarmuka akuntansi.
class BudgetFilterBar extends StatelessWidget {
  /// Membuat [BudgetFilterBar].
  const BudgetFilterBar({
    required this.statusFilter,
    required this.statusCounts,
    required this.wallets,
    required this.walletFilter,
    required this.onStatusChanged,
    required this.onWalletChanged,
    super.key,
  });

  /// Penyaring status aktif.
  final BudgetStatusFilter statusFilter;

  /// Jumlah anggaran per status.
  final Map<BudgetStatusFilter, int> statusCounts;

  /// Dompet yang dipakai sedikitnya satu anggaran.
  final List<Wallet> wallets;

  /// Dompet tersaring, atau `null`.
  final String? walletFilter;

  /// Dipanggil dengan status baru.
  final ValueChanged<BudgetStatusFilter> onStatusChanged;

  /// Dipanggil dengan dompet baru, atau `null` untuk semua dompet.
  final ValueChanged<String?> onWalletChanged;

  String _label(BudgetStatusFilter filter) {
    final label = switch (filter) {
      BudgetStatusFilter.all => t.budget.filterAll,
      BudgetStatusFilter.active => t.budget.filterActive,
      BudgetStatusFilter.finished => t.budget.filterFinished,
      BudgetStatusFilter.archived => t.budget.filterArchived,
    };
    return '$label (${statusCounts[filter] ?? 0})';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Wallet? selected;
    for (final wallet in wallets) {
      if (wallet.id == walletFilter) selected = wallet;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TransactionSlab(
          color: colors.surfaceMid,
          padding: const EdgeInsets.all(AppSpacing.xs),
          shadow: 2,
          child: Row(
            children: [
              for (final filter in BudgetStatusFilter.values) ...[
                if (filter != BudgetStatusFilter.values.first) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _StatusTab(
                    label: _label(filter),
                    selected: statusFilter == filter,
                    onTap: () => onStatusChanged(filter),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppMenuSelectButton<String>(
          icon: selected == null ? IconKey.wallets : walletIconKey(selected.iconKey),
          label: selected?.name ?? t.budget.filterWalletAll,
          options: [
            for (final wallet in wallets) (value: wallet.id, label: wallet.name, icon: walletIconKey(wallet.iconKey)),
          ],
          allLabel: t.budget.filterWalletAll,
          allIcon: IconKey.wallets,
          onSelected: onWalletChanged,
        ),
      ],
    );
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? colors.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            boxShadow: selected ? [BoxShadow(color: colors.edge, offset: const Offset(0, 2))] : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: transactionLabelStyle(context, color: selected ? colors.textPrimary : colors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
