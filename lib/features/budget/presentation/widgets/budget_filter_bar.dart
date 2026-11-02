import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
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
                if (filter != _shown.first) const SizedBox(width: 8),
                DsFilterChip(
                  label: _label(filter),
                  selected: statusFilter == filter,
                  onTap: () => onStatusChanged(filter),
                ),
              ],
            ],
          ),
        ),
        if (wallets.length > 1) ...[
          const SizedBox(height: 8),
          DsFieldGroup(
            children: [
              DsSelectRow<String>(
                icon: Icons.account_balance_wallet_outlined,
                leading: DsIconTile.asset(
                  asset: selected == null
                      ? ClayIcons.walletNav
                      : ClayIcons.forIcon(walletIconKey(selected.iconKey)) ?? ClayIcons.walletNav,
                  size: DsIconTileSize.sm,
                ),
                label: t.budget.filterWalletAll,
                title: selected?.name ?? t.budget.filterWalletAll,
                placeholder: selected == null,
                allLabel: t.budget.filterWalletAll,
                options: [
                  for (final wallet in wallets)
                    DsMenuOption(
                      value: wallet.id,
                      label: wallet.name,
                      leading: SvgPicture.asset(
                        ClayIcons.forIcon(walletIconKey(wallet.iconKey)) ?? ClayIcons.walletNav,
                      ),
                    ),
                ],
                onSelected: onWalletChanged,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
