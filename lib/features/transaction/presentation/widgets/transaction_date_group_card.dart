import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Satu tanggal, satu [AppHardCard] -- header (tanggal + jumlah bersih hari
/// itu, TIDAK menghitung transfer) di atas daftar transaksinya (FR-TXN-004).
class TransactionDateGroupCard extends StatelessWidget {
  /// Membuat [TransactionDateGroupCard].
  const TransactionDateGroupCard({required this.group, required this.walletsById, super.key});

  /// Kelompok satu tanggal, sudah tersaring dan terurut oleh
  /// `TransactionBloc`.
  final TransactionDateGroup group;

  /// Peta `id` dompet -> [Wallet], untuk menerjemahkan `walletId` tiap baris
  /// jadi nama.
  final Map<String, Wallet> walletsById;

  String _dateLabel(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final yesterday = todayOnly.subtract(const Duration(days: 1));
    if (date == todayOnly) return t.transaction.todayLabel;
    if (date == yesterday) return t.transaction.yesterdayLabel;
    return CycleMonthFormatter.formatDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return AppHardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_dateLabel(group.date), style: Theme.of(context).textTheme.titleMedium),
              ),
              AppMoneyText(sen: group.netSen, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          for (var i = 0; i < group.transactions.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            TransactionRow(transaction: group.transactions[i], walletsById: walletsById),
          ],
        ],
      ),
    );
  }
}

/// Satu baris transaksi: ikon jenis, judul (kategori atau catatan), dompet +
/// jam, nominal berwarna+bertanda per jenis, dan lencana jenis kecil.
///
/// SENGAJA tidak interaktif (tanpa `onTap`/riak sentuh) -- T-2.11 (layar
/// rincian transaksi) belum ada, dan menampilkan baris yang terlihat bisa
/// diketuk tapi tidak melakukan apa pun lebih menyesatkan daripada tidak
/// interaktif sama sekali (pola yang sama seperti `_ComingSoonTab`).
class TransactionRow extends StatelessWidget {
  /// Membuat [TransactionRow].
  const TransactionRow({required this.transaction, required this.walletsById, super.key});

  /// Transaksi yang ditampilkan.
  final Transaction transaction;

  /// Peta `id` dompet -> [Wallet].
  final Map<String, Wallet> walletsById;

  String _walletName(String id) => walletsById[id]?.name ?? '—';

  String _time(DateTime date) => '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String _title() {
    final category = transaction.categoryKey;
    if (category != null && category.isNotEmpty) return category;
    if (transaction.note.isNotEmpty) return transaction.note;
    return t.transaction.untitledTransaction;
  }

  String _subtitle() => switch (transaction) {
    IncomeTransaction(:final walletId) => '${_walletName(walletId)} · ${_time(transaction.date)}',
    ExpenseTransaction(:final walletId) => '${_walletName(walletId)} · ${_time(transaction.date)}',
    TransferTransaction(:final fromWalletId, :final toWalletId) =>
      '${_walletName(fromWalletId)} → ${_walletName(toWalletId)} · ${_time(transaction.date)}',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (icon, color, badge, amountText) = switch (transaction) {
      IncomeTransaction() => (
        IconKey.income,
        colors.income,
        t.transaction.incomeBadge,
        '+${AppMoneyFormatter.format(transaction.amount)}',
      ),
      ExpenseTransaction() => (
        IconKey.expense,
        colors.expense,
        t.transaction.expenseBadge,
        '−${AppMoneyFormatter.format(transaction.amount)}',
      ),
      TransferTransaction() => (
        IconKey.transfer,
        colors.transfer,
        t.transaction.transferBadge,
        AppMoneyFormatter.format(transaction.amount),
      ),
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: AppIcon(icon, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(_subtitle(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amountText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            _TypeBadge(label: badge, color: color),
          ],
        ),
      ],
    );
  }
}

/// Lencana jenis kecil ("+MASUK"/"-KELUAR"/"# MUTASI") pada tiap baris.
///
/// Bukan [AppChip] -- [AppChip] menegakkan area sentuh minimum 44px (UX-31,
/// benar untuk chip yang BISA diketuk), sedangkan lencana ini murni
/// dekoratif/informatif per baris (tidak ada `onTap`) sehingga area sentuh
/// sebesar itu hanya akan membuat daftar transaksi jadi tidak proporsional
/// padat. Warna dan bentuknya tetap mengikuti bahasa visual ADR-015.
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.fullAll,
        border: Border.all(color: colors.edge, width: AppBorder.thick),
      ),
      child: Text(label, style: AppTheme.shout(fontSize: 10, color: colors.background)),
    );
  }
}
