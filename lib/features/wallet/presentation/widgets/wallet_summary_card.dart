import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';

/// Kartu ringkasan layar Dompet (rujukan visual `pixel_kas_daftar_dompet`):
/// judul "Dompet Saya" + lencana jumlah kantong aktif, total saldo seluruh
/// dompet aktif, dan catatan bahwa saldo dihitung dari catatan manual.
///
/// Total negatif tampil dengan warna `expense` dan tanda minus (FR-WAL-003) --
/// itu keadaan nyata, bukan kesalahan.
class WalletSummaryCard extends StatelessWidget {
  /// Membuat [WalletSummaryCard].
  const WalletSummaryCard({required this.activeCount, required this.totalBalance, super.key});

  /// Jumlah dompet aktif.
  final int activeCount;

  /// Total saldo tercatat dompet aktif, sen.
  final int totalBalance;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return TransactionSlab(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `Wrap`: lencana turun baris, bukan meluap, pada teks besar.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text(t.wallet.heading, style: textTheme.titleLarge),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.tinted(colors.incomeFill, 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  t.wallet.activeBadge(count: activeCount).toUpperCase(),
                  style: transactionLabelStyle(context, color: colors.income),
                ),
              ),
            ],
          ),
          Text(t.wallet.subtitle, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.wallet.totalLabel.toUpperCase(), style: transactionLabelStyle(context, color: colors.textMuted)),
                const SizedBox(height: 2),
                FitStart(
                  child: Text(
                    AppMoneyFormatter.format(totalBalance),
                    style: textTheme.headlineMedium?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: totalBalance < 0 ? colors.expense : colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: colors.surfaceHigh, borderRadius: BorderRadius.circular(8)),
            child: Text.rich(
              TextSpan(
                style: textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: '${t.wallet.manualNoteTitle}: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: t.wallet.manualNoteBody),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
