part of 'wallet_detail_page.dart';

// Bagian layar rincian dompet (dipecah dari `wallet_detail_page.dart`, ADR-030 A9).

/// Bilah atas: kembali di kiri, sunting (ikon) di kanan -- sama pola seperti
/// `_TopBar` pada `TransactionDetailPage`.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    // Bar atas halaman turunan (design system TopBar `--sub`).
    return SizedBox(
      height: AppSize.topbar,
      child: Row(
        children: [
          AppIconButton(
            icon: IconKey.back,
            label: t.wallet.detailBackLabel,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          AppIconButton(icon: IconKey.edit, label: t.wallet.detailEditAction, onPressed: onEdit),
        ],
      ),
    );
  }
}

/// Kartu utama: ikon, nama, lencana jenis/nonaktif, dan saldo tercatat besar
/// (merah + tanda minus kalau negatif, FR-WAL-003).
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typeLabel = walletTypeLabel(wallet.iconKey);
    return Opacity(
      opacity: wallet.isActive ? 1 : 0.6,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          children: [
            AppIconTile(walletIconKey(wallet.iconKey), size: 48),
            const SizedBox(height: AppSpacing.space2),
            Text(
              wallet.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.space1,
              runSpacing: 4,
              children: [
                if (typeLabel != null) _Badge(label: typeLabel),
                if (!wallet.isActive)
                  _Badge(label: t.wallet.inactiveBadge, color: colors.warning),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              t.wallet.currentBalanceLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.ink2),
            ),
            HeroAmount(AppMoneyFormatter.format(wallet.currentBalance)),
          ],
        ),
      ),
    );
  }
}

/// Ringkasan bulan berjalan untuk dompet ini (T-2.8, direvisi 25 September
/// 2026): pemasukan, pengeluaran, transfer masuk/keluar, dan perubahan saldo.
///
/// Pemasukan dan pengeluaran TIDAK menyertakan transfer (CLAUDE.md aturan 7,
/// sama seperti `TransactionMonthHeader._totals` di tab Transaksi). Tetapi di
/// tingkat SATU dompet transfer adalah perubahan saldo yang nyata -- tanpa
/// baris transfer, dompet yang hanya diisi lewat transfer (mis. Tabungan)
/// selalu tampil Rp0 walau saldonya naik. Karena itu transfer tampil di baris
/// sendiri berwarna `transfer` (bukan hijau/merah, supaya tidak terbaca
/// sebagai pemasukan/pengeluaran), dan angka penutupnya "Perubahan saldo"
/// (pemasukan − pengeluaran + transfer masuk − transfer keluar), bukan
/// "Neto" -- istilah itu di tab Transaksi berarti pemasukan − pengeluaran.
class _MonthSummaryRow extends StatelessWidget {
  const _MonthSummaryRow({required this.transactions, required this.walletId});

  /// Transaksi bulan ini yang menyentuh dompet ini (belum dipotong ke 5
  /// baris terbaru) -- ringkasan harus mencerminkan SELURUH bulan, bukan
  /// hanya baris yang ditampilkan.
  final List<Transaction> transactions;

  /// Dompet yang diringkas -- menentukan arah tiap transfer.
  final String walletId;

  ({int income, int expense, int transferIn, int transferOut}) get _totals {
    var income = 0;
    var expense = 0;
    var transferIn = 0;
    var transferOut = 0;
    for (final transaction in transactions) {
      switch (transaction) {
        case IncomeTransaction():
          income += transaction.amount;
        case ExpenseTransaction():
          expense += transaction.amount;
        case TransferTransaction(:final fromWalletId, :final toWalletId):
          if (toWalletId == walletId) transferIn += transaction.amount;
          if (fromWalletId == walletId) transferOut += transaction.amount;
      }
    }
    return (
      income: income,
      expense: expense,
      transferIn: transferIn,
      transferOut: transferOut,
    );
  }

  /// Nominal bertanda: `+` untuk positif, `-` (dari formatter) untuk negatif.
  String _signed(int sen) => sen > 0
      ? '+${AppMoneyFormatter.format(sen)}'
      : AppMoneyFormatter.format(sen);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final totals = _totals;
    final hasTransfers = totals.transferIn != 0 || totals.transferOut != 0;
    final change =
        totals.income -
        totals.expense +
        totals.transferIn -
        totals.transferOut;
    final changeColor = change > 0
        ? colors.positive
        : change < 0
        ? colors.ink
        : colors.ink;
    return AppCard(
      color: colors.surface2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: t.wallet.detailIncomeLabel,
                  amount: AppMoneyFormatter.format(totals.income),
                  color: colors.positive,
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: t.wallet.detailExpenseLabel,
                  amount: AppMoneyFormatter.format(totals.expense),
                  color: colors.ink,
                ),
              ),
            ],
          ),
          if (hasTransfers) ...[
            const SizedBox(height: AppSpacing.space2),
            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: t.wallet.detailTransferInLabel,
                    amount: _signed(totals.transferIn),
                    color: colors.ink2,
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: t.wallet.detailTransferOutLabel,
                    amount: _signed(-totals.transferOut),
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.space2),
          Divider(color: colors.line, height: 1),
          const SizedBox(height: AppSpacing.space2),
          _SummaryStat(
            label: t.wallet.detailBalanceChangeLabel,
            amount: _signed(change),
            color: changeColor,
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: labelSmStyle(
            context,
            color: context.appColors.ink2,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            amount,
            style: labelSmStyle(context, size: 14, color: color),
          ),
        ),
      ],
    );
  }
}

/// Keadaan kosong "belum ada transaksi bulan ini untuk dompet ini" -- ikon +
/// judul + deskripsi, bahasa visual yang sama dengan `TransactionEmptyMonthState`
/// dan `WalletEmptyState` (hanya diperkecil skalanya karena ini bagian dari
/// halaman, bukan seluruh layar; CTA "Catat" sudah ada di atas, tidak
/// diulang di sini).
class _EmptyRecentTransactions extends StatelessWidget {
  const _EmptyRecentTransactions();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(IconKey.transactions, size: 48, color: colors.ink2),
            const SizedBox(height: AppSpacing.space2),
            Text(
              t.wallet.detailRecentEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              t.wallet.detailRecentEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => AppBadge(label, tone: toneFromColor(context.appColors, color));
}
