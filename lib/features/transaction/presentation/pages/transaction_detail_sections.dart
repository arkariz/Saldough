part of 'transaction_detail_page.dart';

// Bagian layar rincian transaksi (dipecah dari `transaction_detail_page.dart`, ADR-030 A9).

/// Bilah atas: kembali di kiri, ubah dan hapus (ikon) di kanan. Tanpa
/// [onEdit]/[onDelete], hanya tombol kembali (transaksi milik pembayaran
/// freelance).
class _TopBar extends StatelessWidget {
  const _TopBar({this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
                    t.transaction.detailBackLabel.toUpperCase(),
                    style: transactionLabelStyle(context, size: 12, color: colors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          if (onEdit case final onEdit?)
            _SquareAction(
              icon: IconKey.edit,
              color: colors.cardBackground,
              iconColor: colors.textPrimary,
              semanticLabel: t.transaction.editAction,
              onTap: onEdit,
            ),
          if (onDelete case final onDelete?) ...[
            const SizedBox(width: AppSpacing.xs),
            _SquareAction(
              icon: IconKey.delete,
              color: colors.tinted(colors.expenseFill, 0.16),
              iconColor: colors.expense,
              semanticLabel: t.transaction.deleteAction,
              onTap: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconKey icon;
  final Color color;
  final Color iconColor;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              child: AppIcon(icon, size: 20, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu utama: lencana jenis ("Pengeluaran tercatat"), nominal besar
/// berwarna dan bertanda, judul, dan tanggal + jam.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (kind, badge, amountText) = switch (transaction) {
      IncomeTransaction() => (
        TransactionKind.income,
        t.transaction.detailIncomeTitle,
        '+${AppMoneyFormatter.format(transaction.amount)}',
      ),
      ExpenseTransaction() => (
        TransactionKind.expense,
        t.transaction.detailExpenseTitle,
        '−${AppMoneyFormatter.format(transaction.amount)}',
      ),
      TransferTransaction() => (
        TransactionKind.transfer,
        t.transaction.detailTransferTitle,
        AppMoneyFormatter.format(transaction.amount),
      ),
    };
    final ink = colors.kindInk(kind);
    final textTheme = Theme.of(context).textTheme;

    return TransactionSlab(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Kategori + lencana notifikasi asal (ADR-032 §3.10).
          TransactionIcon.of(transaction, size: 56),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: colors.tinted(colors.kindFill(kind), 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(badge.toUpperCase(), style: transactionLabelStyle(context, color: ink)),
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(amountText, style: textTheme.headlineMedium?.copyWith(color: ink)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            transactionTitle(transaction),
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppIcon(IconKey.calendar, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  '${CycleMonthFormatter.formatDateWithWeekday(transaction.date)} • ${transactionTime(transaction.date)}',
                  style: transactionLabelStyle(context, color: colors.textMuted).copyWith(fontWeight: FontWeight.w400),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kartu rincian: jenis, kategori, dompet (+ saldo saat ini), atau pasangan
/// Dari / Ke / Jumlah untuk transfer, lalu catatan manual.
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
    final colors = context.appColors;
    final tx = transaction;
    final typeLabel = switch (tx) {
      IncomeTransaction() => t.transaction.detailIncomeType,
      ExpenseTransaction() => t.transaction.detailExpenseType,
      TransferTransaction() => t.transaction.detailTransferType,
    };
    final category = ActiveCategories.byId(tx.categoryId);

    return TransactionSlab(
      shadow: 0,
      color: colors.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Row(
            label: t.transaction.detailTypeLabel,
            value: Text(typeLabel, style: _valueStyle(context)),
          ),
          if (category != null) ...[
            const _Gap(),
            _Row(
              label: t.transaction.detailCategoryLabel,
              value: _CategoryChip(category: category),
            ),
          ],
          const _Gap(),
          switch (tx) {
            IncomeTransaction(:final walletId) => _WalletRow(
              label: t.transaction.detailIncomeWalletLabel,
              wallet: walletsById[walletId],
            ),
            ExpenseTransaction(:final walletId) => _WalletRow(
              label: t.transaction.detailExpenseWalletLabel,
              wallet: walletsById[walletId],
            ),
            TransferTransaction(:final fromWalletId, :final toWalletId) => _TransferPair(
              from: walletsById[fromWalletId],
              to: walletsById[toWalletId],
              amount: tx.amount,
            ),
          },
          if (budgetItem case final item?) ...[
            const _Gap(),
            _BudgetRow(item: item, onOpen: onOpenBudget),
          ],
          if (tx.note.isNotEmpty) ...[
            const _Gap(),
            Text(
              t.transaction.detailNoteLabel.toUpperCase(),
              style: transactionLabelStyle(context, color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(color: colors.surfaceMid, borderRadius: BorderRadius.circular(4)),
              child: Text(
                '“${tx.note}”',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Baris "Anggaran": pos · anggaran, dan tautan ke rincian anggarannya
/// (T-4.11, FR-TXN-006).
class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.item, required this.onOpen});

  final BudgetItemOption item;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final open = onOpen;
    return Semantics(
      button: open != null,
      child: GestureDetector(
        onTap: open,
        behavior: HitTestBehavior.opaque,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.transaction.budgetLabel.toUpperCase(),
                    style: transactionLabelStyle(context, color: colors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const AppIcon(IconKey.budget, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: Text('${item.itemName} · ${item.budgetName}', style: _valueStyle(context))),
                    ],
                  ),
                  if (open != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      t.transaction.openBudgetAction.toUpperCase(),
                      style: transactionLabelStyle(context, color: colors.accent),
                    ),
                  ],
                ],
              ),
            ),
            if (open != null) const AppIcon(IconKey.chevronRight),
          ],
        ),
      ),
    );
  }
}

TextStyle? _valueStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700);

class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) => const SizedBox(height: AppSpacing.md);
}

/// Satu baris "label ........ nilai": label di kiri, nilai di kanan kalau
/// muat sebaris. Kalau tidak muat -- nilai panjang, layar sempit, atau teks
/// besar dari pengaturan aksesibilitas -- nilai turun ke baris di bawah label
/// dan boleh membungkus, alih-alih meluap atau terpotong. Itu sebabnya
/// [Wrap], bukan `Row` dengan `Expanded`: `Row` tidak pernah turun baris,
/// jadi label yang lebar langsung mengecilkan nilai sampai tidak terbaca.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appColors.textMuted)),
          value,
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: colors.surfaceMid, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(categoryIcon(category), size: 18),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(category.name, style: transactionLabelStyle(context, size: 12, color: colors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

/// Dompet asal/tujuan pemasukan atau pengeluaran, beserta saldo saat ini.
class _WalletRow extends StatelessWidget {
  const _WalletRow({required this.label, required this.wallet});

  final String label;
  final Wallet? wallet;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final wallet = this.wallet;
    return _Row(
      label: label,
      value: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(wallet == null ? IconKey.wallets : walletIconKey(wallet.iconKey), size: 22),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(wallet?.name ?? '—', style: _valueStyle(context), textAlign: TextAlign.end),
              ),
            ],
          ),
          if (wallet != null)
            Text(
              '${t.transaction.detailCurrentBalance}: ${AppMoneyFormatter.format(wallet.currentBalance)}',
              style: transactionLabelStyle(context, color: colors.textMuted).copyWith(fontWeight: FontWeight.w400),
            ),
        ],
      ),
    );
  }
}

/// Tata letak transfer: kartu Dari, panah, kartu Ke, lalu Jumlah. Sesuai
/// FR-TXN-006, judulnya "Transfer tercatat" ada di kartu utama.
///
/// Kartu ditumpuk VERTIKAL dan masing-masing selebar penuh, bukan
/// berdampingan: versi berdampingan memberi tiap sisi paruh lebar layar dikurangi
/// ikon panah, jadi nama dompet yang panjang ("Rekening Bank Central Asia
/// Utama") atau teks besar dari pengaturan aksesibilitas langsung terpotong.
/// Di sini nama boleh membungkus ke banyak baris dan TIDAK PERNAH dipotong.
class _TransferPair extends StatelessWidget {
  const _TransferPair({required this.from, required this.to, required this.amount});

  final Wallet? from;
  final Wallet? to;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final money = AppMoneyFormatter.format(amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PairCard(label: t.transaction.detailFromLabel, wallet: from, delta: '−$money', deltaColor: colors.expense),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Center(child: AppIcon(IconKey.transfer, size: 28)),
        ),
        _PairCard(label: t.transaction.detailToLabel, wallet: to, delta: '+$money', deltaColor: colors.income),
        const SizedBox(height: AppSpacing.md),
        _Row(
          label: t.transaction.detailAmountLabel,
          value: Text(money, style: PixelTypography.tabularMono(context, color: colors.transfer)),
        ),
      ],
    );
  }
}

/// Satu sisi transfer (Dari atau Ke): ikon jenis dompet di kiri; di kanannya
/// label, nama dompet (membungkus, tidak dipotong), saldo saat ini, dan
/// perubahan saldo akibat transfer ini.
class _PairCard extends StatelessWidget {
  const _PairCard({required this.label, required this.wallet, required this.delta, required this.deltaColor});

  final String label;
  final Wallet? wallet;
  final String delta;
  final Color deltaColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final wallet = this.wallet;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: colors.surfaceMid, borderRadius: BorderRadius.circular(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(wallet == null ? IconKey.wallets : walletIconKey(wallet.iconKey), size: 32),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: transactionLabelStyle(context, size: 9, color: colors.textMuted)),
                Text(wallet?.name ?? '—', style: _valueStyle(context)),
                if (wallet != null)
                  Text(
                    '${t.transaction.detailCurrentBalance}: ${AppMoneyFormatter.format(wallet.currentBalance)}',
                    style: transactionLabelStyle(
                      context,
                      color: colors.textMuted,
                    ).copyWith(fontWeight: FontWeight.w400),
                  ),
                const SizedBox(height: AppSpacing.xs),
                // Nominal besar tidak boleh terpotong: kecilkan, bukan elipsis.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(delta, style: transactionLabelStyle(context, size: 13, color: deltaColor)),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final colors = context.appColors;
    return TransactionSlab(
      shadow: 0,
      color: colors.surfaceMid,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(IconKey.locked, size: 20, color: colors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteLink extends StatelessWidget {
  const _DeleteLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(IconKey.delete, size: 18, color: colors.expense),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                t.transaction.deleteAction.toUpperCase(),
                textAlign: TextAlign.center,
                style: transactionLabelStyle(context, size: 12, color: colors.expense),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
