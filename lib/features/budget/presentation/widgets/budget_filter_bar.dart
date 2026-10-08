import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_state.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Penyaring layar Anggaran (FR-BUD-006): empat chip status, lalu satu
/// pilihan dompet. Sengaja sederhana — daftar dan pilihan, bukan
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

  static const List<BudgetStatusFilter> _shown = [
    BudgetStatusFilter.active,
    BudgetStatusFilter.finished,
    BudgetStatusFilter.all,
  ];

  String _label(BudgetStatusFilter filter) {
    final label = switch (filter) {
      BudgetStatusFilter.all => t.budget.filterAll,
      BudgetStatusFilter.active => t.budget.filterActive,
      BudgetStatusFilter.finished => t.budget.filterFinished,
      BudgetStatusFilter.archived => t.budget.filterArchived,
    };
    return label;
  }

  @override
  Widget build(BuildContext context) {
    Wallet? selected;
    for (final wallet in wallets) {
      if (wallet.id == walletFilter) selected = wallet;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chip, bukan baris tab: segmen Rencana sudah bertab di atasnya
        // (PLAN_TAB_LAYOUT §3.2, KT-L2). Bergulir horizontal di layar sempit.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Aktif · Selesai · Semua, tanpa angka (PLAN_TAB_LAYOUT §4.9);
              // anggaran nonaktif tetap terlihat di Semua.
              for (final filter in _shown) ...[
                if (filter != _shown.first) const SizedBox(width: AppSpacing.space1),
                AppChip(
                  label: _label(filter),
                  selected: statusFilter == filter,
                  onTap: () => onStatusChanged(filter),
                ),
              ],
            ],
          ),
        ),
        if (wallets.length > 1) ...[
          const SizedBox(height: AppSpacing.space2),
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
      ],
    );
  }
}
