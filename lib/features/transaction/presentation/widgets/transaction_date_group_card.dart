import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/features/transaction/presentation/transaction_display.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Satu tanggal: judul (ikon, hari/tanggal, jumlah bersih hari itu --
/// TIDAK menghitung transfer) di atas, lalu tiap transaksinya sebagai kartu
/// sendiri (FR-TXN-004), persis rujukan visual `pixel_kas_daftar_transaksi`.
class TransactionDateGroupCard extends StatelessWidget {
  /// Membuat [TransactionDateGroupCard].
  const TransactionDateGroupCard({
    required this.group,
    required this.walletsById,
    this.onTransactionTap,
    super.key,
  });

  /// Kelompok satu tanggal, sudah tersaring dan terurut oleh
  /// `TransactionBloc`.
  final TransactionDateGroup group;

  /// Peta `id` dompet -> [Wallet], untuk menerjemahkan `walletId` tiap baris
  /// jadi nama.
  final Map<String, Wallet> walletsById;

  /// Dipanggil dengan transaksi yang diketuk (membuka layar rincian).
  final ValueChanged<Transaction>? onTransactionTap;

  /// Judul kelompok dan, untuk "Hari Ini"/"Kemarin", tanggal ringkasnya.
  (String title, String? date) _dateLabel(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final yesterday = todayOnly.subtract(const Duration(days: 1));
    final short = CycleMonthFormatter.formatDateShort(date);
    if (date == todayOnly) return (t.transaction.todayLabel, short);
    if (date == yesterday) return (t.transaction.yesterdayLabel, short);
    return (short, null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (title, date) = _dateLabel(group.date);
    final net = group.netSen;
    final (chipFill, chipText) = net > 0
        ? (colors.tinted(colors.kindFill(TransactionKind.income), 0.18), colors.kindInk(TransactionKind.income))
        : net < 0
        ? (colors.tinted(colors.kindFill(TransactionKind.expense), 0.16), colors.kindInk(TransactionKind.expense))
        : (colors.surfaceHigh, colors.textMuted);
    final netText = net > 0 ? '+${AppMoneyFormatter.format(net)}' : AppMoneyFormatter.format(net);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          // `Wrap`, bukan `Row`: pada teks besar (aksesibilitas) atau layar
          // sempit, judul + tanggal dan chip jumlah bersih tidak muat sebaris;
          // chip turun ke baris berikutnya alih-alih meluap atau terpotong.
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon(IconKey.calendar, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                    ),
                    if (date != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          date,
                          style: transactionLabelStyle(
                            context,
                            color: colors.textMuted,
                          ).copyWith(fontWeight: FontWeight.w400),
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(color: chipFill, borderRadius: BorderRadius.circular(4)),
                  child: Text(netText, style: transactionLabelStyle(context, color: chipText)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var i = 0; i < group.transactions.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          TransactionRow(
            transaction: group.transactions[i],
            walletsById: walletsById,
            onTap: onTransactionTap == null ? null : () => onTransactionTap!(group.transactions[i]),
          ),
        ],
      ],
    );
  }
}

/// Satu kartu transaksi: kotak ikon jenis berwarna, judul (kategori atau
/// catatan), dompet + jam, nominal berwarna+bertanda per jenis, dan lencana
/// jenis kecil.
///
/// Diketuk membuka layar rincian (T-2.11) lewat [onTap]. Tanpa riak sentuh
/// (dimatikan global oleh `PixelTheme`); baris `null` [onTap] tidak
/// interaktif.
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

  /// Baris kedua: `Dompet • 09:30`, atau `Asal → Tujuan • 09:30` untuk
  /// transfer (nama dompetnya ditebalkan, seperti rujukan visual). Boleh dua
  /// baris: dengan satu baris, nama asal yang panjang menyembunyikan tujuannya
  /// sama sekali ("Rekening Bank Central …").
  Widget _subtitle(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall;
    final strong = muted?.copyWith(
      color: context.appColors.textPrimary,
      fontWeight: FontWeight.w700,
    );
    final time = ' • ${transactionTime(transaction.date)}';
    return switch (transaction) {
      TransferTransaction(:final fromWalletId, :final toWalletId) => Text.rich(
        TextSpan(
          style: muted,
          children: [
            TextSpan(text: _walletName(fromWalletId), style: strong),
            const TextSpan(text: ' → '),
            TextSpan(text: _walletName(toWalletId), style: strong),
            TextSpan(text: time),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      IncomeTransaction(:final walletId) || ExpenseTransaction(:final walletId) => Text(
        '${_walletName(walletId)}$time',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: muted,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Tiap jenis punya WARNA-nya sendiri di lima tempat sekaligus (garis
    // aksen, kotak ikon, nominal, lencana, nuansa latar) supaya terbedakan
    // sekilas saat menggulir: hijau = masuk, merah = keluar, biru = mutasi.
    // Lihat [TransactionKindPalette] untuk alasan pemilihan warnanya.
    final (kind, icon, badge, amountText) = switch (transaction) {
      IncomeTransaction() => (
        TransactionKind.income,
        IconKey.income,
        t.transaction.incomeBadge,
        '+${AppMoneyFormatter.format(transaction.amount)}',
      ),
      ExpenseTransaction() => (
        TransactionKind.expense,
        IconKey.expense,
        t.transaction.expenseBadge,
        '−${AppMoneyFormatter.format(transaction.amount)}',
      ),
      TransferTransaction() => (
        TransactionKind.transfer,
        IconKey.transfer,
        t.transaction.transferBadge,
        AppMoneyFormatter.format(transaction.amount),
      ),
    };
    final tint = colors.kindFill(kind);
    final ink = colors.kindInk(kind);

    final card = TransactionSlab(
      color: colors.tinted(tint, 0.07),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(color: tint, child: const SizedBox(width: 6)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.tinted(tint, 0.22),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(color: Color.lerp(ink, colors.textPrimary, 0.4)!, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: AppIcon(icon, size: 30),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transactionTitle(transaction),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            _subtitle(context),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(amountText, style: PixelTypography.tabularMono(context, color: ink)),
                          const SizedBox(height: 4),
                          _TypeBadge(label: badge, color: ink),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
  }
}

/// Lencana jenis ("+MASUK"/"-KELUAR"/"# MUTASI") pada tiap baris -- isian
/// SOLID warna jenis dengan teks terbalik, bukan tint pucat, karena lencana
/// inilah penanda jenis yang paling cepat terbaca.
///
/// Bukan [AppChip] -- [AppChip] menegakkan area sentuh minimum 44px (UX-31,
/// benar untuk chip yang BISA diketuk), sedangkan lencana ini murni
/// dekoratif/informatif per baris (tidak ada `onTap`) sehingga area sentuh
/// sebesar itu hanya akan membuat daftar transaksi jadi tidak proporsional
/// padat.
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label.toUpperCase(), style: transactionLabelStyle(context, size: 9, color: colors.cardBackground)),
    );
  }
}
