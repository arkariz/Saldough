import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Baris chip jenis transaksi (Semua/Pemasukan/Pengeluaran/Transfer),
/// masing-masing dengan jumlah ("Semua 42"). SENGAJA `Row` di dalam
/// `SingleChildScrollView(scrollDirection: Axis.horizontal)`, BUKAN `Wrap`
/// -- `Wrap` adalah bug yang sama yang membuat chip CATAT tampil bertumpuk
/// vertikal alih-alih sebaris yang bisa digeser (lihat catatan pengerjaan
/// T-2.5 di TASK_LIST.md).
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

  /// Jumlah transaksi per jenis (sudah tersaring dompet/kategori).
  final Map<TransactionTypeFilter, int> typeCounts;

  /// Dipanggil dengan jenis yang baru dipilih.
  final ValueChanged<TransactionTypeFilter> onChanged;

  String _label(TransactionTypeFilter filter) {
    final count = typeCounts[filter] ?? 0;
    return switch (filter) {
      TransactionTypeFilter.all => t.transaction.allFilterLabel(count: count),
      TransactionTypeFilter.income => t.transaction.incomeFilterLabel(count: count),
      TransactionTypeFilter.expense => t.transaction.expenseFilterLabel(count: count),
      TransactionTypeFilter.transfer => t.transaction.transferFilterLabel(count: count),
    };
  }

  Color _color(BuildContext context, TransactionTypeFilter filter) {
    final colors = context.appColors;
    return switch (filter) {
      TransactionTypeFilter.all => Theme.of(context).colorScheme.primary,
      TransactionTypeFilter.income => colors.income,
      TransactionTypeFilter.expense => colors.expense,
      TransactionTypeFilter.transfer => colors.transfer,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in TransactionTypeFilter.values) ...[
            if (filter != TransactionTypeFilter.values.first) const SizedBox(width: AppSpacing.xs),
            AppChip(
              label: _label(filter),
              selected: typeFilter == filter,
              color: _color(context, filter),
              onTap: () => onChanged(filter),
            ),
          ],
        ],
      ),
    );
  }
}

/// Penyaring dompet dan kategori sebagai dua kontrol dropdown ringkas,
/// berdampingan -- memenuhi FR-TXN-004 ("penyaring dompet dan kategori")
/// tanpa harus meniru persis tata letak chip mockup untuk elemen ini
/// (mockup adalah panduan, bukan spesifikasi -- lihat catatan lingkup T-2.5
/// di TASK_LIST.md). Kategori diisi dari [categoryOptions], yang sudah
/// dihitung `TransactionBloc` dari kunci kategori DISTINCT yang benar-benar
/// muncul bulan ini -- BUKAN daftar tetap (kategori adalah data bebas,
/// `PROJECT_GLOSSARY.md` §"Konvensi penamaan").
class TransactionWalletCategoryFilterRow extends StatelessWidget {
  /// Membuat [TransactionWalletCategoryFilterRow].
  const TransactionWalletCategoryFilterRow({
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FilterDropdown<String?>(
            label: t.transaction.walletFilterLabel,
            value: walletFilter,
            items: [
              DropdownMenuItem(child: Text(t.transaction.walletFilterAllLabel)),
              for (final wallet in wallets) DropdownMenuItem(value: wallet.id, child: Text(wallet.name)),
            ],
            onChanged: onWalletChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _FilterDropdown<String?>(
            label: t.transaction.categoryFilterLabel,
            value: categoryFilter,
            items: [
              DropdownMenuItem(child: Text(t.transaction.categoryFilterAllLabel)),
              for (final category in categoryOptions) DropdownMenuItem(value: category, child: Text(category)),
            ],
            onChanged: onCategoryChanged,
          ),
        ),
      ],
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({required this.label, required this.value, required this.items, required this.onChanged});

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppHardCard(
      elevation: AppHardElevation.flat,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const AppIcon(IconKey.chevronRight, size: 18),
          hint: Text(label, style: TextStyle(color: colors.textMuted)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
