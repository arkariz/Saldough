import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/presentation/transaction_display.dart';
import 'package:saldough/shared/transaction/presentation/transaction_icon.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Satu baris transaksi bergaya v2 (Beranda, rincian dompet, Riwayat): ikon
/// clay bila kategorinya sudah digambar, ikon piksel lama di tile datar bila belum (KT-DS5), judul,
/// nominal bertanda, dompet dan jam, serta nama kategori.
class TransactionLedgerRow extends StatelessWidget {
  /// Membuat [TransactionLedgerRow].
  const TransactionLedgerRow({required this.transaction, required this.walletsById, this.onTap, super.key});

  /// Transaksi yang ditampilkan.
  final Transaction transaction;

  /// Peta `id` dompet -> [Wallet].
  final Map<String, Wallet> walletsById;

  /// Dipanggil saat baris diketuk.
  final VoidCallback? onTap;

  String _walletName(String id) => walletsById[id]?.name ?? '—';

  String get _subtitle {
    final time = transactionTime(transaction.date);
    return switch (transaction) {
      TransferTransaction(:final fromWalletId, :final toWalletId) =>
        '${_walletName(fromWalletId)} → ${_walletName(toWalletId)} · $time',
      IncomeTransaction(:final walletId) || ExpenseTransaction(:final walletId) => '${_walletName(walletId)} · $time',
    };
  }

  @override
  Widget build(BuildContext context) {
    final (moneyKind, rowKind, txKind) = switch (transaction) {
      IncomeTransaction() => (MoneyKind.income, DsLedgerKind.income, TransactionKind.income),
      ExpenseTransaction() => (MoneyKind.expense, DsLedgerKind.expense, TransactionKind.expense),
      TransferTransaction() => (MoneyKind.transfer, DsLedgerKind.transfer, TransactionKind.transfer),
    };
    final iconKey = TransactionIcon.iconKeyFor(
      kind: txKind,
      categoryId: transaction.categoryId,
      title: transaction.note,
    );
    final clay = transaction.sourceIconId == null ? ClayIcons.forIcon(iconKey) : null;
    final category = txKind == TransactionKind.transfer ? null : ActiveCategories.byId(transaction.categoryId);
    return DsLedgerRow(
      leading: clay != null
          ? DsIconTile.asset(
              asset: clay,
              tone: txKind == TransactionKind.income ? DsIconTileTone.income : DsIconTileTone.neutral,
            )
          : SizedBox.square(
              dimension: 40,
              child: Center(child: TransactionIcon.of(transaction, ringColor: context.ds.colors.surfaceCard)),
            ),
      title: transactionTitle(transaction),
      amount: AppMoneyText.format(transaction.amount, moneyKind),
      subtitle: _subtitle,
      badge: category == null
          ? null
          : DsBadge(
              label: category.name,
              tone: txKind == TransactionKind.income ? DsBadgeTone.income : DsBadgeTone.category,
            ),
      kind: rowKind,
      onTap: onTap,
    );
  }
}
