part of 'transaction_detail_page.dart';

// Bagian layar rincian transaksi (dipecah dari `transaction_detail_page.dart`, ADR-030 A9).

/// Bilah atas: hanya tombol kembali. Ubah dan hapus ada di tombol bawah
/// layar, jadi tidak diulang di sini.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          DsIconButton(
            icon: Icons.arrow_back,
            label: t.transaction.detailBackLabel,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

/// Ubin ikon transaksi: ikon clay kategori bila sudah digambar, ikon piksel
/// lama (dengan lencana notifikasi asal) di tile datar bila belum (KT-DS5).
Widget _transactionTile(BuildContext context, Transaction transaction, {DsIconTileSize size = DsIconTileSize.md}) {
  final txKind = switch (transaction) {
    IncomeTransaction() => TransactionKind.income,
    ExpenseTransaction() => TransactionKind.expense,
    TransferTransaction() => TransactionKind.transfer,
  };
  final iconKey = TransactionIcon.iconKeyFor(
    kind: txKind,
    categoryId: transaction.categoryId,
    title: transaction.note,
  );
  final clay = transaction.sourceIconId == null ? ClayIcons.forIcon(iconKey) : null;
  if (clay != null) {
    return DsIconTile.asset(
      asset: clay,
      size: size,
      tone: txKind == TransactionKind.income ? DsIconTileTone.income : DsIconTileTone.neutral,
    );
  }
  return SizedBox.square(
    dimension: 48,
    child: Center(child: TransactionIcon.of(transaction, ringColor: context.ds.colors.surfaceCard)),
  );
}

/// Kartu utama: ikon, lencana jenis ("Pengeluaran tercatat"), nominal besar
/// bertanda, judul, dan tanggal + jam.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final (badge, tone, amountText, ink) = switch (transaction) {
      IncomeTransaction() => (
        t.transaction.detailIncomeTitle,
        DsBadgeTone.income,
        '+${AppMoneyFormatter.format(transaction.amount)}',
        c.income,
      ),
      ExpenseTransaction() => (
        t.transaction.detailExpenseTitle,
        DsBadgeTone.neutral,
        '−${AppMoneyFormatter.format(transaction.amount)}',
        c.textPrimary,
      ),
      TransferTransaction() => (
        t.transaction.detailTransferTitle,
        DsBadgeTone.neutral,
        AppMoneyFormatter.format(transaction.amount),
        c.textSecondary,
      ),
    };
    return DsCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _transactionTile(context, transaction, size: DsIconTileSize.lg),
          const SizedBox(height: 12),
          DsBadge(label: badge, tone: tone),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(amountText, style: ds.typography.numericalDisplay.copyWith(color: ink)),
          ),
          const SizedBox(height: 4),
          Text(
            transactionTitle(transaction),
            textAlign: TextAlign.center,
            style: ds.typography.titleMd.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            '${CycleMonthFormatter.formatDateWithWeekday(transaction.date)} · ${transactionTime(transaction.date)}',
            style: ds.typography.bodySm.copyWith(color: c.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Kartu rincian: jenis, kategori, dompet (+ saldo saat ini), atau pasangan
/// Dari / Ke / Jumlah untuk transfer, anggaran tertaut, lalu catatan.
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.transaction,
    required this.walletsById,
    required this.budgetItem,
    required this.onOpenBudget,
  });

  final Transaction transaction;
  final Map<String, Wallet> walletsById;

  /// Pos anggaran tertaut, atau `null`.
  final BudgetItemOption? budgetItem;

  /// Membuka rincian anggaran [budgetItem], atau `null` kalau tidak bisa.
  final VoidCallback? onOpenBudget;

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final typeLabel = switch (tx) {
      IncomeTransaction() => t.transaction.detailIncomeType,
      ExpenseTransaction() => t.transaction.detailExpenseType,
      TransferTransaction() => t.transaction.detailTransferType,
    };
    final category = ActiveCategories.byId(tx.categoryId);
    final money = AppMoneyFormatter.format(tx.amount);
    return DsListCard(
      children: [
        _InfoRow(label: t.transaction.detailTypeLabel, value: typeLabel),
        if (category != null)
          _InfoRow(
            label: t.transaction.detailCategoryLabel,
            value: category.name,
            leading: _categoryTile(category),
          ),
        ...switch (tx) {
          IncomeTransaction(:final walletId) => [
            _walletRow(t.transaction.detailIncomeWalletLabel, walletsById[walletId]),
          ],
          ExpenseTransaction(:final walletId) => [
            _walletRow(t.transaction.detailExpenseWalletLabel, walletsById[walletId]),
          ],
          TransferTransaction(:final fromWalletId, :final toWalletId) => [
            _walletRow(t.transaction.detailFromLabel, walletsById[fromWalletId], delta: '−$money'),
            _walletRow(t.transaction.detailToLabel, walletsById[toWalletId], delta: '+$money', deltaIncome: true),
            _InfoRow(label: t.transaction.detailAmountLabel, value: money),
          ],
        },
        if (budgetItem case final item?)
          _InfoRow(
            label: t.transaction.budgetLabel,
            value: '${item.itemName} · ${item.budgetName}',
            sub: onOpenBudget == null ? null : t.transaction.openBudgetAction,
            leading: DsIconTile.asset(asset: ClayIcons.forIcon(IconKey.budget) ?? ClayIcons.receipt, size: DsIconTileSize.sm),
            onTap: onOpenBudget,
          ),
        if (tx.note.isNotEmpty) _InfoRow(label: t.transaction.detailNoteLabel, value: '“${tx.note}”', italic: true),
      ],
    );
  }

  Widget _categoryTile(Category category) {
    final clay = ClayIcons.forIcon(categoryIcon(category));
    return clay != null
        ? DsIconTile.asset(asset: clay, size: DsIconTileSize.sm)
        : AppIconTile(categoryIcon(category));
  }

  Widget _walletRow(String label, Wallet? wallet, {String? delta, bool deltaIncome = false}) => _InfoRow(
    label: label,
    value: wallet?.name ?? '—',
    sub: wallet == null
        ? null
        : '${t.transaction.detailCurrentBalance}: ${AppMoneyFormatter.format(wallet.currentBalance)}',
    leading: DsIconTile.asset(
      asset: wallet == null
          ? ClayIcons.walletNav
          : ClayIcons.forIcon(walletIconKey(wallet.iconKey)) ?? ClayIcons.walletNav,
      size: DsIconTileSize.sm,
    ),
    delta: delta,
    deltaIncome: deltaIncome,
  );
}

/// Satu baris rincian: label kecil di atas, nilai di bawahnya (membungkus,
/// tidak dipotong), keterangan opsional, dan nominal perubahan di kanan.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.sub,
    this.leading,
    this.delta,
    this.deltaIncome = false,
    this.italic = false,
    this.onTap,
  });

  final String label;
  final String value;
  final String? sub;
  final Widget? leading;
  final String? delta;
  final bool deltaIncome;
  final bool italic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ds.typography.bodySm.copyWith(color: c.textMuted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: ds.typography.titleMd.copyWith(
                    fontSize: 14,
                    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: ds.typography.bodySm.copyWith(color: onTap != null ? c.actionPrimary : c.textSecondary),
                  ),
              ],
            ),
          ),
          if (delta != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  delta!,
                  style: ds.typography.amountSm.copyWith(color: deltaIncome ? c.income : c.textPrimary),
                ),
              ),
            ),
          ],
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: c.textMuted),
          ],
        ],
      ),
    );
    if (onTap == null) return body;
    return DsPressable(
      onPressed: onTap,
      pressedScale: 0.995,
      dimWhenDisabled: false,
      builder: (context, _) => body,
    );
  }
}

/// Catatan bahwa ini rekaman manual, bukan transaksi yang dijalankan aplikasi
/// -- batas produk Saldough (CLAUDE.md "Apa ini").
class _ManualNote extends StatelessWidget {
  const _ManualNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.mdAll),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, size: 18, color: c.textSecondary),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: ds.typography.bodySm.copyWith(color: c.textSecondary))),
          ],
        ),
      ),
    );
  }
}
