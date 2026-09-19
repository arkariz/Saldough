import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/features/transaction/presentation/widgets/transaction_surfaces.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Wadah segmen jenis transaksi (Semua/Masuk/Keluar/Mutasi) ala "kartrid
/// piksel" pada rujukan visual: satu konsol berlatar hangat, tab terpilih
/// menjadi papan putih bersayap bayangan bawah. Tiap label memuat jumlahnya
/// ("Semua 42").
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
  const _TypeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 6,
          ),
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
              style: transactionLabelStyle(
                context,
                color: selected ? colors.textPrimary : colors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kolom pencarian teks dan tombol dompet berdampingan -- baris kedua pada
/// rujukan visual. Pencarian dicocokkan ke kategori, catatan, dan nama dompet.
class TransactionSearchRow extends StatefulWidget {
  /// Membuat [TransactionSearchRow].
  const TransactionSearchRow({
    required this.query,
    required this.onQueryChanged,
    required this.wallets,
    required this.walletFilter,
    required this.onWalletChanged,
    super.key,
  });

  /// Kata kunci aktif di state -- dipakai menyinkronkan kolom saat filter
  /// dihapus dari luar (tombol "Hapus filter").
  final String query;

  /// Dipanggil tiap teks pencarian berubah.
  final ValueChanged<String> onQueryChanged;

  /// Seluruh dompet yang bisa dipilih.
  final List<Wallet> wallets;

  /// `id` dompet aktif, `null` untuk semua dompet.
  final String? walletFilter;

  /// Dipanggil dengan `id` dompet yang baru dipilih, `null` untuk semua.
  final ValueChanged<String?> onWalletChanged;

  @override
  State<TransactionSearchRow> createState() => _TransactionSearchRowState();
}

class _TransactionSearchRowState extends State<TransactionSearchRow> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );

  @override
  void didUpdateWidget(TransactionSearchRow oldWidget) {
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
    final selectedWallet = widget.wallets.where((wallet) => wallet.id == widget.walletFilter).firstOrNull;

    // `IntrinsicHeight`: kolom cari dan tombol dompet harus setinggi sama, dan
    // `stretch` butuh tinggi terbatas -- tinggi di dalam area scroll tidak.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TransactionSlab(
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
                  hintStyle: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                  prefixIcon: AppIcon(
                    IconKey.search,
                    size: 18,
                    color: colors.textMuted,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _FilterMenuButton<Wallet>(
            icon: IconKey.wallets,
            label: selectedWallet?.name ?? t.transaction.walletFilterLabel,
            maxLabelWidth: 96,
            options: [
              for (final wallet in widget.wallets) (value: wallet, label: wallet.name),
            ],
            allLabel: t.transaction.walletFilterAllLabel,
            onSelected: (wallet) => widget.onWalletChanged(wallet?.id),
          ),
        ],
      ),
    );
  }
}

/// Tombol dropdown kategori -- FR-TXN-004 menuntut penyaring kategori walau
/// rujukan visual hanya menampilkan tombol dompet. Kategori diisi dari
/// [categoryOptions], yang dihitung `TransactionBloc` dari kunci DISTINCT
/// yang benar-benar muncul bulan ini -- BUKAN daftar tetap (kategori adalah
/// data bebas, `PROJECT_GLOSSARY.md` §"Konvensi penamaan").
class TransactionCategoryFilter extends StatelessWidget {
  /// Membuat [TransactionCategoryFilter].
  const TransactionCategoryFilter({
    required this.categoryOptions,
    required this.categoryFilter,
    required this.onChanged,
    super.key,
  });

  /// Kunci kategori yang tersedia bulan ini.
  final List<String> categoryOptions;

  /// Kategori aktif, `null` untuk semua kategori.
  final String? categoryFilter;

  /// Dipanggil dengan kategori yang baru dipilih, `null` untuk semua.
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: _FilterMenuButton<String>(
        icon: IconKey.categoryOther,
        label: categoryFilter ?? t.transaction.categoryFilterLabel,
        maxLabelWidth: 200,
        options: [
          for (final category in categoryOptions) (value: category, label: category),
        ],
        allLabel: t.transaction.categoryFilterAllLabel,
        onSelected: onChanged,
      ),
    );
  }
}

/// Tombol putih kecil bergaya rujukan ("Dompet ▾") yang membuka menu pilihan.
/// `null` pada [onSelected] berarti pilihan "Semua".
class _FilterMenuButton<T> extends StatelessWidget {
  const _FilterMenuButton({
    required this.icon,
    required this.label,
    required this.maxLabelWidth,
    required this.options,
    required this.allLabel,
    required this.onSelected,
  });

  final IconKey icon;
  final String label;
  final double maxLabelWidth;
  final List<({T value, String label})> options;
  final String allLabel;
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
        PopupMenuItem<int>(value: -1, child: Text(allLabel)),
        for (var i = 0; i < options.length; i++) PopupMenuItem<int>(value: i, child: Text(options[i].label)),
      ],
      child: TransactionSlab(
        radius: 4,
        shadow: 2,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 16, color: colors.textPrimary),
            const SizedBox(width: AppSpacing.xs),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxLabelWidth),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: transactionLabelStyle(
                  context,
                  color: colors.textPrimary,
                ),
              ),
            ),
            AppIcon(IconKey.dropdown, size: 18, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
