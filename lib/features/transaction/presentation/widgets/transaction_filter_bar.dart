import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Wadah segmen jenis transaksi (Semua/Masuk/Keluar/Mutasi) ala "kartrid
/// piksel" pada rujukan visual: satu konsol berlatar hangat, tab terpilih
/// menjadi papan putih bersayap bayangan bawah. Tiap tab memuat ikon jenisnya
/// (sama dengan ikon pada kartu transaksi) di atas label + jumlahnya
/// ("Semua 42"); tab tidak terpilih diredupkan supaya yang aktif menonjol.
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
      TransactionTypeFilter.income => t.transaction.incomeFilterLabel(count: count),
      TransactionTypeFilter.expense => t.transaction.expenseFilterLabel(count: count),
      TransactionTypeFilter.transfer => t.transaction.transferFilterLabel(count: count),
    };
  }

  IconKey _icon(TransactionTypeFilter filter) => switch (filter) {
    TransactionTypeFilter.all => IconKey.transactions,
    TransactionTypeFilter.income => IconKey.income,
    TransactionTypeFilter.expense => IconKey.expense,
    TransactionTypeFilter.transfer => IconKey.transfer,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TransactionSlab(
      color: colors.surfaceMid,
      padding: const EdgeInsets.all(AppSpacing.xs),
      shadow: 2,
      child: Row(
        children: [
          for (final filter in TransactionTypeFilter.values) ...[
            if (filter != TransactionTypeFilter.values.first) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _TypeTab(
                icon: _icon(filter),
                label: _label(filter),
                selected: typeFilter == filter,
                onTap: () => onChanged(filter),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconKey icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: selected ? [BoxShadow(color: colors.edge, offset: const Offset(0, 2))] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(opacity: selected ? 1 : 0.55, child: AppIcon(icon)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: transactionLabelStyle(context, color: selected ? colors.textPrimary : colors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kolom pencarian teks selebar penuh, dengan ikon kaca pembesar pixel-art.
/// Pencarian dicocokkan ke kategori, catatan, dan nama dompet.
class TransactionSearchField extends StatefulWidget {
  /// Membuat [TransactionSearchField].
  const TransactionSearchField({required this.query, required this.onQueryChanged, super.key});

  /// Kata kunci aktif di state -- dipakai menyinkronkan kolom saat filter
  /// dihapus dari luar (tombol "Hapus filter").
  final String query;

  /// Dipanggil tiap teks pencarian berubah.
  final ValueChanged<String> onQueryChanged;

  @override
  State<TransactionSearchField> createState() => _TransactionSearchFieldState();
}

class _TransactionSearchFieldState extends State<TransactionSearchField> {
  late final TextEditingController _controller = TextEditingController(text: widget.query);

  @override
  void didUpdateWidget(TransactionSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) _controller.text = widget.query;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TransactionSlab(
      padding: EdgeInsets.zero,
      radius: 4,
      shadow: 2,
      child: TextField(
        controller: _controller,
        onChanged: widget.onQueryChanged,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: t.transaction.searchHint,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          prefixIcon: const Padding(padding: EdgeInsets.all(10), child: AppIcon(IconKey.search, size: 22)),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppSpacing.sm),
        ),
      ),
    );
  }
}

/// Tombol tunggal "Filter" yang membuka lembar berisi penyaring dompet DAN
/// kategori (UX-21 -- menggantikan dua dropdown berdampingan
/// `TransactionWalletCategoryRow` supaya kop Transaksi lebih pendek).
/// Menampilkan lencana jumlah filter aktif (0, 1, atau 2).
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

  Future<void> _openSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sm))),
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
    final colors = context.appColors;
    final activeCount = _activeCount;
    return AppTappable(
      onTap: () => _openSheet(context),
      label: activeCount > 0 ? '${t.transaction.filterButtonLabel} ($activeCount)' : t.transaction.filterButtonLabel,
      child: TransactionSlab(
        padding: EdgeInsets.zero,
        radius: 4,
        shadow: 2,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(child: AppIcon(IconKey.filter, size: 22, color: activeCount > 0 ? colors.accent : null)),
              if (activeCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: colors.accent, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      '$activeCount',
                      style: transactionLabelStyle(context, color: colors.onAccent),
                    ),
                  ),
                ),
            ],
          ),
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
    final selectedWallet = wallets.where((wallet) => wallet.id == walletFilter).firstOrNull;
    final selectedCategory = ActiveCategories.byId(categoryFilter);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.transaction.filterSheetTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          AppMenuSelectButton<String>(
            icon: selectedWallet == null ? IconKey.wallets : walletIconKey(selectedWallet.iconKey),
            label: selectedWallet?.name ?? t.transaction.walletFilterLabel,
            options: [
              for (final wallet in wallets) (value: wallet.id, label: wallet.name, icon: walletIconKey(wallet.iconKey)),
            ],
            allLabel: t.transaction.walletFilterAllLabel,
            allIcon: IconKey.wallets,
            wrapLabel: true,
            onSelected: onWalletChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppMenuSelectButton<String>(
            icon: selectedCategory == null ? IconKey.filter : categoryIcon(selectedCategory),
            label: selectedCategory?.name ?? t.transaction.categoryFilterLabel,
            options: [
              for (final id in categoryOptions)
                if (ActiveCategories.byId(id) case final category?)
                  (value: id, label: category.name, icon: categoryIcon(category)),
            ],
            allLabel: t.transaction.categoryFilterAllLabel,
            wrapLabel: true,
            onSelected: onCategoryChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: t.transaction.filterSheetDoneAction, onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
