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

/// Satu tanggal: judul (ikon, hari/tanggal, jumlah bersih hari itu --
/// TIDAK menghitung transfer) di atas, lalu tiap transaksinya sebagai kartu
/// sendiri (FR-TXN-004), persis rujukan visual `pixel_kas_daftar_transaksi`.
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
  /// teratas tab Transaksi, ADR-021); null berarti tidak ada yang disorot.
  final SpotlightKey? firstRowSpotlightKey;

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
        : (colors.surface3, colors.ink2);
    final netText = net > 0 ? '+${AppMoneyFormatter.format(net)}' : AppMoneyFormatter.format(net);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space1,
            vertical: AppSpacing.space1,
          ),
          // `Wrap`, bukan `Row`: pada teks besar (aksesibilitas) atau layar
          // sempit, judul + tanggal dan chip jumlah bersih tidak muat sebaris;
          // chip turun ke baris berikutnya alih-alih meluap atau terpotong.
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space1,
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
                          style: labelSmStyle(
                            context,
                            color: colors.ink2,
                          ).copyWith(fontWeight: FontWeight.w400),
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2, vertical: 2),
                  decoration: BoxDecoration(color: chipFill, borderRadius: BorderRadius.circular(4)),
                  child: Text(netText, style: labelSmStyle(context, color: chipText)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        for (var i = 0; i < group.transactions.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space2),
          SpotlightTarget(
            spotlightKey: i == 0 ? firstRowSpotlightKey : null,
            child: TransactionRow(
              transaction: group.transactions[i],
              walletsById: walletsById,
              onTap: onTransactionTap == null ? null : () => onTransactionTap!(group.transactions[i]),
            ),
          ),
        ],
      ],
    );
  }
}

/// Satu kartu transaksi: [TransactionIcon] (kategori dalam kotak berwarna
/// jenis + lencana notifikasi asal), judul (kategori atau catatan), dompet +
/// jam, dan nominal berwarna+bertanda per jenis.
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

  /// Lebar maksimum kolom nominal + lencana.
  static const _amountMaxWidth = 160.0;

  String _walletName(String id) => walletsById[id]?.name ?? '—';

  /// Baris kedua: `Dompet • 09:30`, atau `Asal → Tujuan • 09:30` untuk
  /// transfer (nama dompetnya ditebalkan, seperti rujukan visual). Boleh dua
  /// baris: dengan satu baris, nama asal yang panjang menyembunyikan tujuannya
  /// sama sekali ("Rekening Bank Central …").
  Widget _subtitle(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall;
    final strong = muted?.copyWith(
      color: context.appColors.ink,
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
    final (kind, amountText) = switch (transaction) {
      IncomeTransaction() => (TransactionKind.income, '+${AppMoneyFormatter.format(transaction.amount)}'),
      ExpenseTransaction() => (TransactionKind.expense, '−${AppMoneyFormatter.format(transaction.amount)}'),
      TransferTransaction() => (TransactionKind.transfer, AppMoneyFormatter.format(transaction.amount)),
    };
    final tint = colors.kindFill(kind);
    final ink = colors.kindInk(kind);

    final background = colors.tinted(tint, 0.07);
    final card = AppCard(
      color: background,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space2),
                  child: Row(
                    children: [
                      // Kategori + lencana notifikasi asal (ADR-032 §3.10).
                      TransactionIcon.of(transaction, ringColor: background),
                      // Celah tetap selebar tonjolan lencana: judul sejajar
                      // di semua baris, berlencana atau tidak.
                      const SizedBox(width: AppSpacing.space2 + TransactionIcon.badgeOverhang),
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
                      const SizedBox(width: AppSpacing.space2),
                      // Lebar kolom nominal dibatasi: nominal mengecil di
                      // layar sempit atau teks diperbesar, bukan meluber
                      // (ketahuan uji Beranda 360px + teks 2x). Tidak memakai
                      // `Flexible`, yang membagi ruang sama rata dengan judul
                      // sehingga judul terpotong walau ruangnya cukup.
                      //
                      // ADR-020 §3.3: satu penanda warna per baris (kotak
                      // ikon), ditambah tanda +/− dan warna pada nominal --
                      // TANPA garis aksen maupun lencana jenis lagi (lencana
                      // "+MASUK"/"-KELUAR" kini hanya di layar rincian).
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: _amountMaxWidth),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(amountText, style: context.numberStyles.amountSm.copyWith(color: ink)),
                        ),
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
    return AppTappable(onTap: onTap, child: card);
  }
}
