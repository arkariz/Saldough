part of 'wallet_detail_page.dart';

// Bagian layar rincian dompet (dipecah dari `wallet_detail_page.dart`, ADR-030 A9).

/// Bilah atas: kembali di kiri, sunting (ikon) di kanan -- sama pola seperti
/// `_TopBar` pada `TransactionDetailPage`.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TransactionSlab(
      color: colors.surfaceMid,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: AppTappable(
              onTap: () => Navigator.of(context).maybePop(),
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.xs),
                  AppIcon(IconKey.chevronLeft, color: colors.textPrimary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    t.wallet.detailBackLabel.toUpperCase(),
                    style: transactionLabelStyle(
                      context,
                      size: 12,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Semantics(
            button: true,
            label: t.wallet.detailEditAction,
            child: GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: AppIcon(
                      IconKey.edit,
                      size: 20,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
    final negative = wallet.currentBalance < 0;
    return Opacity(
      opacity: wallet.isActive ? 1 : 0.6,
      child: TransactionSlab(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surfaceMid,
                borderRadius: BorderRadius.circular(4),
              ),
              child: AppIcon(walletIconKey(wallet.iconKey), size: 44),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              wallet.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: 4,
              children: [
                if (typeLabel != null) _Badge(label: typeLabel),
                if (!wallet.isActive)
                  _Badge(label: t.wallet.inactiveBadge, color: colors.pending),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              t.wallet.currentBalanceLabel.toUpperCase(),
              style: transactionLabelStyle(context, color: colors.textMuted),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppMoneyFormatter.format(wallet.currentBalance),
                style:
                    Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(
                      color: negative ? colors.expense : colors.textPrimary,
                    ),
              ),
            ),
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
        ? colors.income
        : change < 0
        ? colors.expense
        : colors.textPrimary;
    return TransactionSlab(
      color: colors.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: t.wallet.detailIncomeLabel,
                  amount: AppMoneyFormatter.format(totals.income),
                  color: colors.income,
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: t.wallet.detailExpenseLabel,
                  amount: AppMoneyFormatter.format(totals.expense),
                  color: colors.expense,
                ),
              ),
            ],
          ),
          if (hasTransfers) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: t.wallet.detailTransferInLabel,
                    amount: _signed(totals.transferIn),
                    color: colors.transfer,
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: t.wallet.detailTransferOutLabel,
                    amount: _signed(-totals.transferOut),
                    color: colors.transfer,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Divider(color: colors.divider, height: 1),
          const SizedBox(height: AppSpacing.sm),
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
          label.toUpperCase(),
          style: transactionLabelStyle(
            context,
            color: context.appColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            amount,
            style: transactionLabelStyle(context, size: 14, color: color),
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(IconKey.transactions, size: 48, color: colors.textMuted),
            const SizedBox(height: AppSpacing.sm),
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
              ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
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
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surfaceMid,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: transactionLabelStyle(
          context,
          size: 9,
          color: color ?? colors.textMuted,
        ),
      ),
    );
  }
}
