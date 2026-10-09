import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/category/category_presentation.dart';
import 'package:saldough/shared/transaction/transaction.dart';
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


  @override
  Widget build(BuildContext context) {
    // Chip penyaring di atas `bg` (design system Chip, varian filter): satu
    // baris yang bisa digeser, label + jumlah.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final filter in TransactionTypeFilter.values) ...[
            if (filter != TransactionTypeFilter.values.first) const SizedBox(width: AppSpacing.space2),
            AppChip(
              key: ValueKey('type-filter-${filter.name}'),
              label: _label(filter),
              selected: typeFilter == filter,
              onBg: true,
              onTap: () => onChanged(filter),
            ),
          ],
        ],
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
    // Kolom cari design system: pil `surface2` setinggi 48 dengan ikon cari.
    return Container(
      decoration: ShapeDecoration(color: colors.surface2, shape: const PixelCornerBorder.small()),
      child: TextField(
        controller: _controller,
        onChanged: widget.onQueryChanged,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          filled: false,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: t.transaction.searchHint,
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.ink3),
          prefixIcon: Padding(padding: const EdgeInsets.all(12), child: AppIcon(IconKey.search, color: colors.ink2)),
          prefixIconConstraints: const BoxConstraints(minWidth: AppSize.touch, minHeight: AppSize.touch),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppSpacing.space2),
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

  Future<void> _openSheet(BuildContext context) => showAppSheet<void>(
    context,
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
      child: AppCard(
        color: context.appColors.surface2,
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(child: AppIcon(IconKey.filter, size: 22, color: activeCount > 0 ? colors.brand : null)),
              if (activeCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: colors.brand, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      '$activeCount',
                      style: labelSmStyle(context, color: colors.onBrand),
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
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.transaction.filterSheetTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.space4),
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
          const SizedBox(height: AppSpacing.space2),
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
          const SizedBox(height: AppSpacing.space4),
          AppButton(label: t.transaction.filterSheetDoneAction, onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
