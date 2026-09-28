import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';

/// Kartu utama layar Dompet ([AppHeroCard], rujukan visual
/// `pixel_kas_daftar_dompet`): total saldo seluruh dompet aktif sebagai angka
/// utama, lencana jumlah dompet aktif, dan catatan bahwa saldo dihitung dari
/// catatan manual.
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
    return AppHeroCard(
      tour: TourId.wallet,
      icon: IconKey.wallets,
      label: t.wallet.totalLabel,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(
          color: colors.tinted(colors.incomeFill, 0.2),
          borderRadius: AppRadius.pixelSmAll,
        ),
        child: Text(
          t.wallet.activeBadge(count: activeCount).toUpperCase(),
          style: transactionLabelStyle(context, color: colors.income),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroAmount(AppMoneyFormatter.format(totalBalance), color: totalBalance < 0 ? colors.expense : null),
          Text(t.wallet.subtitle, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
        ],
      ),
    );
  }
}
