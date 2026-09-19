import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/features/transaction/presentation/transaction_category_icon.dart';
import 'package:saldough/features/transaction/presentation/widgets/transaction_surfaces.dart';
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

/// Penyaring dompet dan kategori berdampingan, dua tombol dropdown sama lebar
/// (FR-TXN-004). Keduanya SELALU tampil berdua supaya baris tidak berubah
/// bentuk antar bulan; kategori diisi dari [categoryOptions], yang dihitung
/// `TransactionBloc` dari kunci DISTINCT yang benar-benar muncul bulan ini --
/// BUKAN daftar tetap (kategori adalah data bebas, `PROJECT_GLOSSARY.md`
/// §"Konvensi penamaan"). Tiap item bergambar: ikon jenis dompet dari
/// `Wallet.iconKey`, ikon kategori dari [categoryIconFor].
class TransactionWalletCategoryRow extends StatelessWidget {
  /// Membuat [TransactionWalletCategoryRow].
  const TransactionWalletCategoryRow({
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
    final selectedWallet = wallets.where((wallet) => wallet.id == walletFilter).firstOrNull;
    final selectedCategory = categoryFilter;

    return Row(
      children: [
        Expanded(
          child: _FilterMenuButton<String>(
            icon: selectedWallet == null ? IconKey.wallets : walletIconKey(selectedWallet.iconKey),
            label: selectedWallet?.name ?? t.transaction.walletFilterLabel,
            options: [
              for (final wallet in wallets) (value: wallet.id, label: wallet.name, icon: walletIconKey(wallet.iconKey)),
            ],
            allLabel: t.transaction.walletFilterAllLabel,
            allIcon: IconKey.wallets,
            onSelected: onWalletChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _FilterMenuButton<String>(
            icon: selectedCategory == null ? IconKey.filter : categoryIconFor(selectedCategory),
            label: selectedCategory ?? t.transaction.categoryFilterLabel,
            options: [
              for (final category in categoryOptions) (value: category, label: category, icon: categoryIconFor(category)),
            ],
            allLabel: t.transaction.categoryFilterAllLabel,
            allIcon: IconKey.filter,
            onSelected: onCategoryChanged,
          ),
        ),
      ],
    );
  }
}

/// Tombol putih kecil bergaya rujukan ("Dompet ▾") yang membuka menu pilihan
/// bergambar. `null` pada [onSelected] berarti pilihan "Semua". Selebar ruang
/// yang diberikan induknya; label terpotong dengan elipsis kalau panjang.
class _FilterMenuButton<T> extends StatelessWidget {
  const _FilterMenuButton({
    required this.icon,
    required this.label,
    required this.options,
    required this.allLabel,
    required this.allIcon,
    required this.onSelected,
  });

  final IconKey icon;
  final String label;
  final List<({T value, String label, IconKey icon})> options;
  final String allLabel;
  final IconKey allIcon;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopupMenuButton<int>(
      // Indeks, bukan nilai: `PopupMenuButton` tidak memanggil `onSelected`
      // untuk nilai `null`, padahal "Semua" justru diwakili `null`.
      onSelected: (index) => onSelected(index < 0 ? null : options[index].value),
      color: colors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: colors.edge, width: AppBorder.pixelThick),
      ),
      itemBuilder: (_) => [
        _item(value: -1, icon: allIcon, label: allLabel),
        for (var i = 0; i < options.length; i++) _item(value: i, icon: options[i].icon, label: options[i].label),
      ],
      child: TransactionSlab(
        radius: 4,
        shadow: 2,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
        child: Row(
          children: [
            AppIcon(icon, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: transactionLabelStyle(context, color: colors.textPrimary),
              ),
            ),
            AppIcon(IconKey.dropdown, size: 18, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<int> _item({required int value, required IconKey icon, required String label}) {
    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [
          AppIcon(icon),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
