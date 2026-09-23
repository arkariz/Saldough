import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/open_record_sheet.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_detail_page.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_list_page.dart';
import 'package:saldough/features/transaction/presentation/widgets/transaction_date_group_card.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_form_sheet.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_type.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Membuka [WalletDetailPage] untuk [wallet] (T-2.8, FR-WAL-004).
///
/// Rute yang di-push TIDAK mewarisi `Theme` maupun `BlocProvider` dari pohon
/// asalnya (pola yang sama seperti `openTransactionDetail`), jadi ketiganya
/// dipasang ulang di sini: [PixelTheme], `WalletBloc` yang SAMA (sunting/
/// hapus memuat ulang daftar di belakangnya), `TransactionBloc` yang SAMA
/// (untuk riwayat tersaring dan pintasan "Lihat Semua Transaksi"), dan
/// `RecordBloc` yang SAMA (pintasan CATAT, FR-REC-002).
Future<void> openWalletDetail(BuildContext context, Wallet wallet) {
  final walletBloc = context.read<WalletBloc>();
  final transactionBloc = context.read<TransactionBloc>();
  final recordBloc = context.read<RecordBloc>();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PixelTheme(
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: walletBloc),
            BlocProvider.value(value: transactionBloc),
            BlocProvider.value(value: recordBloc),
          ],
          child: WalletDetailPage(wallet: wallet),
        ),
      ),
    ),
  );
}

/// Layar rincian satu dompet (T-2.8, FR-WAL-004): nama, ikon, saldo tercatat,
/// transaksi bulan ini yang menyentuh dompet ini, jalan ke daftar transaksi
/// lengkap tersaring, dan pintasan CATAT dengan dompet ini sudah terpilih
/// (FR-REC-002).
///
/// Membaca dompet dari `WalletBloc` (bukan [wallet] langsung) supaya saldo
/// yang berubah lewat CATAT (pintasan di layar ini sendiri) tampil segar
/// tanpa menutup layar ini -- [wallet] hanya dipakai sebagai cadangan
/// sebelum `WalletBloc` sempat memancarkan salinan terbarunya. Menyunting
/// lewat tombol "Sunting" MENUTUP layar ini sesudah dikirim (lihat
/// dokumentasi `_edit`) -- perubahannya tetap tampil di `WalletListPage` di
/// belakangnya, sama seperti pola `TransactionDetailPage._edit`.
///
/// ⚠ Riwayat di sini HANYA transaksi BULAN BERJALAN, sama seperti tab
/// Transaksi (ADR-012 -- buku besar dipartisi per bulan, `listAllTransactions`
/// reserved untuk penghitungan ulang saldo, bukan untuk merender layar).
class WalletDetailPage extends StatelessWidget {
  /// Membuat [WalletDetailPage] untuk [wallet].
  const WalletDetailPage({required this.wallet, super.key});

  /// Dompet yang ditampilkan (cuplikan saat layar dibuka).
  final Wallet wallet;

  bool _touches(Transaction transaction, String walletId) =>
      switch (transaction) {
        IncomeTransaction(walletId: final id) => id == walletId,
        ExpenseTransaction(walletId: final id) => id == walletId,
        TransferTransaction(:final fromWalletId, :final toWalletId) =>
          fromWalletId == walletId || toWalletId == walletId,
      };

  Future<void> _record(BuildContext context) async {
    final transactions = context.read<TransactionBloc>();
    final wallets = context.read<WalletBloc>();
    await openRecordSheet(context, initialWalletId: wallet.id);
    transactions.add(const TransactionRefreshed());
    wallets.add(const WalletRefreshed());
  }

  /// Sunting selalu menutup layar ini sesudah dikirim (pola yang sama seperti
  /// `TransactionDetailPage._edit`) -- daftar dompet di belakangnya sudah
  /// segar lewat `WalletBloc` yang sama. Hapus BEDA: baru menutup layar ini
  /// kalau penghapusan sungguhan berhasil, karena bisa diblokir (dompet
  /// sudah punya transaksi) dan layar rincian harus tetap menampilkan
  /// dompet yang masih ada beserta pesan blokirnya.
  Future<void> _edit(BuildContext context, Wallet current) async {
    final bloc = context.read<WalletBloc>();
    final navigator = Navigator.of(context);
    final result = await showFullScreenSheet<WalletFormResult>(
      context,
      builder: (_) => WalletFormSheet(initial: current),
    );
    switch (result) {
      case WalletFormSaved(
        :final name,
        :final iconKey,
        :final isActive,
        :final initialBalance,
      ):
        bloc.add(
          WalletEdited(
            original: current,
            name: name,
            iconKey: iconKey,
            isActive: isActive,
            initialBalance: initialBalance,
          ),
        );
        navigator.pop();
      case WalletFormDeleted():
        bloc.add(WalletDeleted(current));
        final state = await bloc.stream.firstWhere((s) => s.effect != null);
        if (!state.wallets.any((w) => w.id == current.id)) navigator.pop();
      case null:
        break;
    }
  }

  Future<void> _viewAllTransactions(
    BuildContext context,
    String walletId,
  ) async {
    final bloc = context.read<TransactionBloc>()
      ..add(TransactionWalletFilterChanged(walletId));
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PixelTheme(
          child: BlocProvider.value(
            value: bloc,
            child: const TransactionListPage(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, walletState) {
            final current = walletState.wallets.firstWhere(
              (w) => w.id == wallet.id,
              orElse: () => wallet,
            );
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _TopBar(onEdit: () => _edit(context, current)),
                const SizedBox(height: AppSpacing.md),
                _HeroCard(wallet: current),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: t.wallet.detailRecordAction,
                  onPressed: () => _record(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSectionLabel(t.wallet.detailRecentHeading),
                const SizedBox(height: AppSpacing.xs),
                BlocBuilder<TransactionBloc, TransactionState>(
                  builder: (context, txState) {
                    if (txState.isLoading) return const SizedBox.shrink();
                    final touched = txState.rawTransactions
                        .where((tx) => _touches(tx, current.id))
                        .toList();
                    final recent = [...touched]
                      ..sort((a, b) => b.date.compareTo(a.date));
                    final walletsById = {
                      for (final w in txState.wallets) w.id: w,
                    };
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MonthSummaryRow(transactions: touched),
                        const SizedBox(height: AppSpacing.md),
                        if (recent.isEmpty)
                          const _EmptyRecentTransactions()
                        else
                          for (var i = 0; i < recent.length && i < 5; i++) ...[
                            if (i > 0) const SizedBox(height: AppSpacing.sm),
                            TransactionRow(
                              transaction: recent[i],
                              walletsById: walletsById,
                              onTap: () =>
                                  openTransactionDetail(context, recent[i]),
                            ),
                          ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: t.wallet.detailViewAllAction,
                  color: context.appColors.textMuted,
                  onPressed: () => _viewAllTransactions(context, current.id),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

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
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
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

/// Ringkasan masuk/keluar/neto bulan berjalan untuk transaksi yang menyentuh
/// dompet ini. Transfer TIDAK dihitung (CLAUDE.md aturan 7 -- transfer tidak
/// pernah dihitung sebagai pemasukan maupun pengeluaran), sama seperti
/// `TransactionMonthHeader._totals` di tab Transaksi.
class _MonthSummaryRow extends StatelessWidget {
  const _MonthSummaryRow({required this.transactions});

  /// Transaksi bulan ini yang menyentuh dompet ini (belum dipotong ke 5
  /// baris terbaru) -- ringkasan harus mencerminkan SELURUH bulan, bukan
  /// hanya baris yang ditampilkan.
  final List<Transaction> transactions;

  ({int income, int expense}) get _totals {
    var income = 0;
    var expense = 0;
    for (final transaction in transactions) {
      switch (transaction) {
        case IncomeTransaction():
          income += transaction.amount;
        case ExpenseTransaction():
          expense += transaction.amount;
        case TransferTransaction():
          break;
      }
    }
    return (income: income, expense: expense);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final totals = _totals;
    final net = totals.income - totals.expense;
    final netColor = net > 0
        ? colors.income
        : net < 0
        ? colors.expense
        : colors.textPrimary;
    return TransactionSlab(
      color: colors.surfaceLow,
      child: Row(
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
          Expanded(
            child: _SummaryStat(
              label: t.wallet.detailNetLabel,
              amount: net > 0
                  ? '+${AppMoneyFormatter.format(net)}'
                  : AppMoneyFormatter.format(net),
              color: netColor,
            ),
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
