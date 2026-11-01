import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Baris chip jenis transaksi (Semua/Pemasukan/Pengeluaran/Transfer) yang
/// bisa digeser mendatar. Tiap chip memuat label dan jumlahnya ("Semua 42");
/// yang terpilih berisi warna utama.
class TransactionTypeFilterRow extends StatelessWidget {
  /// Membuat [TransactionTypeFilterRow].
  const TransactionTypeFilterRow({
    required this.typeFilter,
    required this.typeCounts,
    required this.onChanged,
    super.key,
  });

  /// Filter jenis yang sedang aktif.
  final TransactionTypeFilter typeFilter;

  /// Jumlah transaksi per jenis (sudah tersaring dompet/kategori/pencarian).
  final Map<TransactionTypeFilter, int> typeCounts;

  /// Dipanggil dengan jenis yang baru dipilih.
  final ValueChanged<TransactionTypeFilter> onChanged;

  String _label(TransactionTypeFilter filter) {
    final count = typeCounts[filter] ?? 0;
    return switch (filter) {
      TransactionTypeFilter.all => t.transaction.allFilterLabel(count: count),
      TransactionTypeFilter.income => t.transaction.incomeFilterLabel(
        count: count,
      ),
      TransactionTypeFilter.expense => t.transaction.expenseFilterLabel(
        count: count,
      ),
      TransactionTypeFilter.transfer => t.transaction.transferFilterLabel(
        count: count,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final filter in TransactionTypeFilter.values) ...[
            if (filter != TransactionTypeFilter.values.first) const SizedBox(width: 8),
            DsFilterChip(
              key: ValueKey('type-filter-${filter.name}'),
              label: _label(filter),
              selected: typeFilter == filter,
              onTap: () => onChanged(filter),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kolom cari selebar penuh. Pencarian dicocokkan ke kategori, catatan, dan
/// nama dompet.
class TransactionSearchField extends StatelessWidget {
  /// Membuat [TransactionSearchField].
  const TransactionSearchField({
    required this.query,
    required this.onQueryChanged,
    super.key,
  });

  /// Kata kunci aktif di state -- dipakai menyinkronkan kolom saat filter
  /// dihapus dari luar (tombol "Hapus filter").
  final String query;

  /// Dipanggil tiap teks pencarian berubah.
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) => DsSearchField(
    query: query,
    onChanged: onQueryChanged,
    hint: t.transaction.searchHint,
  );
}

/// Tombol tunggal "Filter" yang membuka lembar berisi penyaring dompet DAN
/// kategori (UX-21). Menampilkan lencana jumlah filter aktif (0, 1, atau 2).
///
/// Kategori diisi dari [categoryOptions], yang dihitung `TransactionBloc`
/// dari kunci DISTINCT yang benar-benar muncul bulan ini -- BUKAN daftar
/// tetap (kategori adalah data bebas, `PROJECT_GLOSSARY.md` §"Konvensi
/// penamaan").
class TransactionFilterButton extends StatelessWidget {
  /// Membuat [TransactionFilterButton].
  const TransactionFilterButton({
    required this.wallets,
    required this.walletFilter,
    required this.onWalletChanged,
    required this.categoryOptions,
    required this.categoryFilter,
    required this.onCategoryChanged,
    super.key,
  });

  /// Seluruh dompet yang bisa dipilih.
  final List<Wallet> wallets;

  /// `id` dompet aktif, `null` untuk semua dompet.
  final String? walletFilter;

  /// Dipanggil dengan `id` dompet yang baru dipilih, `null` untuk semua.
  final ValueChanged<String?> onWalletChanged;

  /// Kunci kategori yang tersedia bulan ini.
  final List<String> categoryOptions;

  /// Kategori aktif, `null` untuk semua kategori.
  final String? categoryFilter;

  /// Dipanggil dengan kategori yang baru dipilih, `null` untuk semua.
  final ValueChanged<String?> onCategoryChanged;

  int get _activeCount => (walletFilter != null ? 1 : 0) + (categoryFilter != null ? 1 : 0);

  Future<void> _openSheet(BuildContext context) => showAppSheet<void>(
    context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(DsRadius.sheet)),
    ),
    builder: (sheetContext) => _TransactionFilterSheet(
      wallets: wallets,
      walletFilter: walletFilter,
      onWalletChanged: onWalletChanged,
      categoryOptions: categoryOptions,
      categoryFilter: categoryFilter,
      onCategoryChanged: onCategoryChanged,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final activeCount = _activeCount;
    final active = activeCount > 0;
    return DsPressable(
      onPressed: () => _openSheet(context),
      semanticLabel: active ? '${t.transaction.filterButtonLabel} ($activeCount)' : t.transaction.filterButtonLabel,
      builder: (context, _) => SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: active ? c.actionPrimary.withValues(alpha: 0.12) : c.surfaceCard,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? c.actionPrimary : c.outlineSubtle,
                  ),
                ),
                child: Icon(
                  Icons.tune,
                  size: 20,
                  color: active ? c.actionPrimary : c.textSecondary,
                ),
              ),
            ),
            if (active)
              Positioned(
                right: -2,
                top: -2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.actionPrimary,
                    borderRadius: DsRadius.fullAll,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    child: Text(
                      '$activeCount',
                      style: ds.typography.labelMd.copyWith(
                        fontSize: 11,
                        color: c.onActionPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TransactionFilterSheet extends StatelessWidget {
  const _TransactionFilterSheet({
    required this.wallets,
    required this.walletFilter,
    required this.onWalletChanged,
    required this.categoryOptions,
    required this.categoryFilter,
    required this.onCategoryChanged,
  });

  final List<Wallet> wallets;
  final String? walletFilter;
  final ValueChanged<String?> onWalletChanged;
  final List<String> categoryOptions;
  final String? categoryFilter;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final selectedWallet = wallets.where((wallet) => wallet.id == walletFilter).firstOrNull;
    final selectedCategory = ActiveCategories.byId(categoryFilter);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.transaction.filterSheetTitle,
            style: ds.typography.headlineMd.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 16),
          DsFieldGroup(
            children: [
              DsSelectRow<String>(
                icon: Icons.account_balance_wallet_outlined,
                leading: selectedWallet == null
                    ? null
                    : DsIconTile.asset(
                        asset:
                            ClayIcons.forIcon(
                              walletIconKey(selectedWallet.iconKey),
                            ) ??
                            ClayIcons.walletNav,
                        size: DsIconTileSize.sm,
                      ),
                label: t.transaction.walletFilterLabel,
                title: selectedWallet?.name ?? t.transaction.walletFilterAllLabel,
                placeholder: selectedWallet == null,
                allLabel: t.transaction.walletFilterAllLabel,
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
              DsSelectRow<String>(
                icon: Icons.sell_outlined,
                label: t.transaction.categoryFilterLabel,
                title: selectedCategory?.name ?? t.transaction.categoryFilterAllLabel,
                placeholder: selectedCategory == null,
                allLabel: t.transaction.categoryFilterAllLabel,
                options: [
                  for (final id in categoryOptions)
                    if (ActiveCategories.byId(id) case final category?) DsMenuOption(value: id, label: category.name),
                ],
                onSelected: onCategoryChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
          DsButton(
            label: t.transaction.filterSheetDoneAction,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
