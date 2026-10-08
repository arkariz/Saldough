import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Satu hari di Riwayat (pola Daftar design system): kepala "Hari ini ·
/// Senin, 28 Sep" di kiri dan selisih hari itu (tanpa transfer) di kanan,
/// lalu satu kartu daftar berisi transaksinya (FR-TXN-004).
class TransactionDateGroupCard extends StatelessWidget {
  /// Membuat [TransactionDateGroupCard].
  const TransactionDateGroupCard({
    required this.group,
    required this.walletsById,
    this.onTransactionTap,
    this.firstRowSpotlightKey,
    super.key,
  });

  /// Kunci tur untuk baris pertama kelompok ini (mis. `txnRow` di kelompok
  /// teratas tab Riwayat, ADR-021); null berarti tidak ada yang disorot.
  final SpotlightKey? firstRowSpotlightKey;

  /// Kelompok satu tanggal, sudah tersaring dan terurut oleh
  /// `TransactionBloc`.
  final TransactionDateGroup group;

  /// Peta `id` dompet -> [Wallet], untuk nama dompet tiap baris.
  final Map<String, Wallet> walletsById;

  /// Dipanggil dengan transaksi yang diketuk (membuka layar rincian).
  final ValueChanged<Transaction>? onTransactionTap;

  /// "Hari ini · Senin, 28 Sep", "Kemarin · …", atau "Sabtu, 26 Sep".
  static String dayLabel(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final day = DateTime(date.year, date.month, date.day);
    final dated = '${CycleMonthFormatter.formatWeekday(day)}, ${CycleMonthFormatter.formatDayMonth(day)}'
        '${day.year == today.year ? '' : ' ${day.year}'}';
    if (day == todayOnly) return '${t.transaction.todayLabel} · $dated';
    if (day == todayOnly.subtract(const Duration(days: 1))) return '${t.transaction.yesterdayLabel} · $dated';
    return dated;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final net = group.netSen;
    final netText = net > 0 ? '+${AppMoneyFormatter.format(net)}' : AppMoneyFormatter.format(net);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
          // `Wrap`: pada teks besar selisih turun ke baris berikutnya.
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.space2,
              children: [
                Semantics(
                  header: true,
                  child: Text(dayLabel(group.date), style: textTheme.labelLarge?.copyWith(color: colors.ink2)),
                ),
                Text(netText, style: context.numberStyles.amountSm.copyWith(color: colors.ink2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        AppListCard(
          children: [
            for (var i = 0; i < group.transactions.length; i++)
              SpotlightTarget(
                spotlightKey: i == 0 ? firstRowSpotlightKey : null,
                child: TransactionRow(
                  transaction: group.transactions[i],
                  walletsById: walletsById,
                  onTap: onTransactionTap == null ? null : () => onTransactionTap!(group.transactions[i]),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Satu baris transaksi (komponen ListRow, varian transaksi): tile kategori
/// dengan lencana notifikasi asal, judul (catatan, atau nama kategori bila
/// catatan kosong), subjudul "Dompet · 08.00" atau "BCA → Tunai · 08.00", dan
/// nominal bertanda di kanan (pengeluaran `ink`, pemasukan `positive`,
/// transfer `ink2`). Tanpa latar berwarna per jenis.
///
/// Diletakkan di dalam `AppListCard` oleh pemanggil; diketuk membuka layar
/// rincian (T-2.11) lewat [onTap].
class TransactionRow extends StatelessWidget {
  /// Membuat [TransactionRow].
  const TransactionRow({
    required this.transaction,
    required this.walletsById,
    this.onTap,
    super.key,
  });

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
    final kind = switch (transaction) {
      IncomeTransaction() => MoneyKind.income,
      ExpenseTransaction() => MoneyKind.expense,
      TransferTransaction() => MoneyKind.transfer,
    };
    return AppListRow(
      leading: TransactionIcon.of(transaction, ringColor: context.appColors.surface),
      title: transactionTitle(transaction),
      subtitle: _subtitle,
      trailing: AppMoneyText(transaction.amount, kind: kind),
      onTap: onTap,
    );
  }
}
