part of 'wallet_detail_page.dart';

// Bagian layar rincian dompet (dipecah dari `wallet_detail_page.dart`, ADR-030 A9).

/// Bilah atas: kembali di kiri, sunting (ikon) di kanan -- sama pola seperti
/// `_TopBar` pada `TransactionDetailPage`.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          DsIconButton(
            icon: Icons.arrow_back,
            label: t.wallet.detailBackLabel,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          DsIconButton(icon: Icons.tune, label: t.wallet.detailEditAction, onPressed: onEdit),
        ],
      ),
    );
  }
}

/// Total bulan berjalan satu dompet. Pemasukan dan pengeluaran TIDAK
/// menyertakan transfer (aturan 7, sama seperti kepala bulan tab Transaksi);
/// transfer masuk dan keluar dipisah, dan [change] adalah perubahan saldo
/// (pemasukan − pengeluaran + transfer masuk − transfer keluar).
class _MonthTotals {
  const _MonthTotals({
    required this.income,
    required this.expense,
    required this.transferIn,
    required this.transferOut,
  });

  factory _MonthTotals.of(List<Transaction> transactions, String walletId) {
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
    return _MonthTotals(income: income, expense: expense, transferIn: transferIn, transferOut: transferOut);
  }

  final int income;
  final int expense;
  final int transferIn;
  final int transferOut;

  bool get hasTransfers => transferIn != 0 || transferOut != 0;

  int get change => income - expense + transferIn - transferOut;
}

/// Nominal bertanda: `+` untuk positif, `-` (dari formatter) untuk negatif.
String _signed(int sen) => sen > 0 ? '+${AppMoneyFormatter.format(sen)}' : AppMoneyFormatter.format(sen);

/// Kartu hero rincian (acuan Rincian Dompet v2): nama dompet, jenis dan
/// status, saldo tercatat yang menghitung naik dan bisa disembunyikan,
/// pemasukan dan pengeluaran bulan ini, serta porsi dari total saldo. Memakai
/// `DsHeroBalanceCard`; ikon clay jenis dompet menggantikan maskot. Saldo
/// negatif ditulis bertanda minus (FR-WAL-003). Nomor rekening dan nama
/// pemilik di acuan tidak ada di domain, jadi tidak ditampilkan.
class _Hero extends StatelessWidget {
  const _Hero({required this.wallet, required this.shareText, required this.totals});

  final Wallet wallet;

  /// Porsi saldo ("55%"), atau `null`.
  final String? shareText;

  /// Total bulan ini, atau `null` selagi dimuat.
  final _MonthTotals? totals;

  @override
  Widget build(BuildContext context) {
    final symbol = ActiveCurrency.value.symbol;
    final typeLabel = walletTypeLabel(wallet.iconKey);
    final caption = [?typeLabel, if (!wallet.isActive) t.wallet.inactiveBadge].join(' · ');
    final asset = ClayIcons.forIcon(walletIconKey(wallet.iconKey)) ?? ClayIcons.walletNav;
    final totals = this.totals;
    return Opacity(
      opacity: wallet.isActive ? 1 : 0.7,
      child: DsCountUp(
        value: wallet.currentBalance,
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (context, shown) => DsHeroBalanceCard(
          label: wallet.name.toUpperCase(),
          currencySymbol: symbol,
          semanticAmount: AppMoneyFormatter.formatRevealed(wallet.currentBalance),
          mascot: SvgPicture.asset(asset),
          amount: AppMoneyFormatter.formatRevealed(shown).replaceFirst(symbol, ''),
          hidden: AmountVisibility.hidden,
          toggleLabel: AmountVisibility.hidden ? t.home.showAmounts : t.home.hideAmounts,
          onToggleHidden: AmountVisibility.toggle,
          caption: caption.isEmpty ? null : caption,
          stats: totals == null
              ? const []
              : [
                  DsHeroStatTile(
                    icon: Icons.arrow_circle_up,
                    label: t.wallet.detailIncomeLabel.toUpperCase(),
                    value: AppMoneyText.format(totals.income, MoneyKind.income),
                  ),
                  DsHeroStatTile(
                    icon: Icons.arrow_circle_down,
                    label: t.wallet.detailExpenseLabel.toUpperCase(),
                    value: AppMoneyText.format(totals.expense, MoneyKind.expense),
                    income: false,
                  ),
                ],
          footer: shareText == null
              ? null
              : Text(
                  t.wallet.detailShare(percent: shareText!),
                  key: const ValueKey('wallet-detail-share'),
                  style: context.ds.typography.bodySm.copyWith(color: context.ds.colors.onHeroMuted),
                ),
        ),
      ),
    );
  }
}

/// Tiga aksi cepat (clay): Catat transaksi di dompet ini, Catat Transfer dari
/// dompet ini, dan Riwayat tersaring. Semua pencatatan lewat CATAT (aturan 8).
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onRecord, required this.onTransfer, required this.onHistory});

  final VoidCallback onRecord;
  final VoidCallback onTransfer;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DsQuickActionTile(
            key: const ValueKey('wallet-detail-record'),
            tile: DsIconTile.asset(asset: ClayIcons.note, tone: DsIconTileTone.income),
            label: t.wallet.detailRecordAction,
            onPressed: onRecord,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DsQuickActionTile(
            key: const ValueKey('wallet-detail-transfer'),
            tile: DsIconTile.asset(asset: ClayIcons.transfer),
            label: t.home.actionTransfer,
            onPressed: onTransfer,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DsQuickActionTile(
            key: const ValueKey('wallet-detail-history'),
            tile: DsIconTile.asset(asset: ClayIcons.receipt, tone: DsIconTileTone.info),
            label: t.wallet.detailHistoryAction,
            onPressed: onHistory,
          ),
        ),
      ],
    );
  }
}

/// Ringkasan perubahan bulan berjalan: transfer masuk dan keluar (hanya bila
/// ada, karena di satu dompet transfer adalah perubahan saldo yang nyata) dan
/// "Perubahan saldo" sebagai penutup.
class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.totals});

  final _MonthTotals totals;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    Widget stat(String label, String amount, Color color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ds.typography.pixelCaption.copyWith(color: c.textMuted, fontSize: 10)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(amount, style: ds.typography.amount.copyWith(color: color, fontSize: 15)),
          ),
        ],
      ),
    );
    final change = totals.change;
    return DsCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.wallet.detailMonthHeading.toUpperCase(),
            style: ds.typography.pixelCaption.copyWith(color: c.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 8),
          if (totals.hasTransfers) ...[
            Row(
              children: [
                stat(t.wallet.detailTransferInLabel, _signed(totals.transferIn), c.textSecondary),
                stat(t.wallet.detailTransferOutLabel, _signed(-totals.transferOut), c.textSecondary),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: c.outlineSubtle, height: 1),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              stat(t.wallet.detailBalanceChangeLabel, _signed(change), change > 0 ? c.income : c.textPrimary),
            ],
          ),
        ],
      ),
    );
  }
}

/// Keadaan kosong "belum ada transaksi bulan ini untuk dompet ini".
class _EmptyRecentTransactions extends StatelessWidget {
  const _EmptyRecentTransactions();

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return DsCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          DsIconTile.asset(asset: ClayIcons.emptyTray, size: DsIconTileSize.lg),
          const SizedBox(height: 12),
          Text(t.wallet.detailRecentEmptyTitle, style: ds.typography.titleMd.copyWith(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            t.wallet.detailRecentEmpty,
            textAlign: TextAlign.center,
            style: ds.typography.bodySm.copyWith(fontSize: 12, color: ds.colors.textMuted),
          ),
        ],
      ),
    );
  }
}
