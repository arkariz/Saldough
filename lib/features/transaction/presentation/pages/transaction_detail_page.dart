import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/record/presentation/open_edit_transaction_sheet.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/features/transaction/presentation/transaction_display.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Layar rincian satu transaksi (T-2.11, FR-TXN-006): jenis, nominal,
/// kategori, dompet, tanggal, catatan, beserta aksi ubah dan hapus (T-2.6,
/// FR-TXN-005) -- rujukan visual `pixel_kas_detail_transaksi_1`.
///
/// Transfer memakai judul "Transfer tercatat" dan tata letak Dari / Ke /
/// Jumlah. Kosakata yang menyiratkan aplikasi menjalankan transaksi
/// ("Transfer berhasil", "Pembayaran berhasil", "Kirim Uang") DILARANG di
/// mana pun -- Saldough hanya mencatat.
///
/// TIDAK ditampilkan: baris "Pos Anggaran" (baru terisi setelah Fase 4;
/// bagiannya tidak ditampilkan, bukan ditampilkan kosong), "ID catatan"
/// (transaksi tidak punya nomor tampilan), dan kartu "Format Entri Transfer"
/// (ilustrasi desain, bukan fitur).
///
/// Membaca dompet dari [TransactionBloc] (nama dan "saldo saat ini"), jadi
/// harus berada di bawah `BlocProvider<TransactionBloc>` -- lihat
/// `openTransactionDetail`, yang memasangnya karena rute yang di-push tidak
/// mewarisi provider dari pohon asalnya.
class TransactionDetailPage extends StatelessWidget {
  /// Membuat [TransactionDetailPage] untuk [transaction].
  const TransactionDetailPage({required this.transaction, super.key});

  /// Transaksi yang ditampilkan (cuplikan saat layar dibuka; layar ini
  /// ditutup setelah sunting/hapus, jadi tidak perlu mengikuti perubahan).
  final Transaction transaction;

  Set<String> get _walletIds => switch (transaction) {
    IncomeTransaction(:final walletId) => {walletId},
    ExpenseTransaction(:final walletId) => {walletId},
    TransferTransaction(:final fromWalletId, :final toWalletId) => {fromWalletId, toWalletId},
  };

  Future<void> _edit(BuildContext context, TransactionState state) async {
    final bloc = context.read<TransactionBloc>();
    final navigator = Navigator.of(context);
    // Dompet nonaktif tetap ditawarkan kalau transaksi ini memakainya, supaya
    // pilihan awal formulir tidak hilang.
    final wallets = [
      for (final w in state.wallets)
        if (w.isActive || _walletIds.contains(w.id)) w,
    ];
    final updated = await openEditTransactionSheet(
      context,
      transaction: transaction,
      wallets: wallets,
      budgetItems: state.budgetItems,
    );
    if (updated == null || updated == transaction) return;
    bloc.add(TransactionUpdated(original: transaction, updated: updated));
    navigator.pop();
  }

  Future<void> _delete(BuildContext context) async {
    final bloc = context.read<TransactionBloc>();
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDelete(
      context,
      title: t.transaction.deleteConfirmTitle,
      message: t.transaction.deleteConfirmMessage,
    );
    if (!confirmed) return;
    bloc.add(TransactionDeleted(transaction));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, state) {
            final walletsById = {for (final wallet in state.wallets) wallet.id: wallet};
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _TopBar(onEdit: () => _edit(context, state), onDelete: () => _delete(context)),
                const SizedBox(height: AppSpacing.md),
                _HeroCard(transaction: transaction),
                const SizedBox(height: AppSpacing.md),
                _DetailsCard(transaction: transaction, walletsById: walletsById),
                const SizedBox(height: AppSpacing.md),
                const _ManualNote(),
                const SizedBox(height: AppSpacing.md),
                AppButton(label: t.transaction.editAction, onPressed: () => _edit(context, state)),
                const SizedBox(height: AppSpacing.sm),
                _DeleteLink(onPressed: () => _delete(context)),
                const SizedBox(height: AppSpacing.md),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Bilah atas: kembali di kiri, ubah dan hapus (ikon) di kanan.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TransactionSlab(
      color: colors.surfaceMid,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
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
          _SquareAction(
            icon: IconKey.edit,
            color: colors.cardBackground,
            iconColor: colors.textPrimary,
            semanticLabel: t.transaction.editAction,
            onTap: onEdit,
          ),
          const SizedBox(width: AppSpacing.xs),
          _SquareAction(
            icon: IconKey.delete,
            color: colors.tinted(colors.expenseFill, 0.16),
            iconColor: colors.expense,
            semanticLabel: t.transaction.deleteAction,
            onTap: onDelete,
          ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: colors.tinted(colors.kindFill(kind), 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(badge.toUpperCase(), style: transactionLabelStyle(context, size: 11, color: ink)),
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
  const _DetailsCard({required this.transaction, required this.walletsById});

  final Transaction transaction;
  final Map<String, Wallet> walletsById;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tx = transaction;
    final typeLabel = switch (tx) {
      IncomeTransaction() => t.transaction.detailIncomeType,
      ExpenseTransaction() => t.transaction.detailExpenseType,
      TransferTransaction() => t.transaction.detailTransferType,
    };
    final category = tx.categoryKey;

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
          if (category != null && category.isNotEmpty) ...[
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

  final String category;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: colors.surfaceMid, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(categoryIconFor(category), size: 18),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(category, style: transactionLabelStyle(context, size: 12, color: colors.textPrimary)),
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
  const _ManualNote();

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
              t.transaction.detailManualNote,
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

/// Membuka [TransactionDetailPage] untuk [transaction].
///
/// Rute yang di-push TIDAK mewarisi `Theme` maupun `BlocProvider` dari pohon
/// asalnya (beda dengan `showModalBottomSheet`, yang menangkap tema): jadi
/// keduanya dipasang ulang di sini -- [PixelTheme] supaya rute ini tampil
/// dengan bahasa visual ADR-015 alih-alih tema global lama, dan `TransactionBloc`
/// yang SAMA (bukan instance baru) supaya sunting/hapus memuat ulang daftar
/// di belakangnya.
Future<void> openTransactionDetail(BuildContext context, Transaction transaction) {
  final bloc = context.read<TransactionBloc>();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PixelTheme(
        child: BlocProvider.value(
          value: bloc,
          child: TransactionDetailPage(transaction: transaction),
        ),
      ),
    ),
  );
}
