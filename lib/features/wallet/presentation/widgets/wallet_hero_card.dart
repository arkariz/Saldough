import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';

/// Kartu hero tab Dompet (acuan Dompet v2): total saldo seluruh dompet aktif
/// yang menghitung naik, dengan tombol mata dan pita "N dompet aktif". Memakai
/// `DsHeroBalanceCard` yang sama dengan Beranda, tanpa kotak Masuk/Keluar
/// (arus transaksi bukan milik fitur Dompet).
class WalletHeroCard extends StatelessWidget {
  /// Membuat [WalletHeroCard].
  const WalletHeroCard({required this.total, required this.activeCount, super.key});

  /// Total saldo dompet aktif, sen.
  final int total;

  /// Jumlah dompet aktif.
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final symbol = ActiveCurrency.value.symbol;
    return DsCountUp(
      value: total,
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, shown) => DsHeroBalanceCard(
        label: t.home.balanceLabel.toUpperCase(),
        currencySymbol: symbol,
        semanticAmount: AppMoneyFormatter.formatRevealed(total),
        mascot: SvgPicture.asset(ClayIcons.mascot),
        coin: SvgPicture.asset(ClayIcons.tierCoin, width: 24, height: 24),
        amount: AppMoneyFormatter.formatRevealed(shown).replaceFirst(symbol, ''),
        hidden: AmountVisibility.hidden,
        toggleLabel: AmountVisibility.hidden ? t.home.showAmounts : t.home.hideAmounts,
        onToggleHidden: AmountVisibility.toggle,
        caption: t.wallet.activeBadge(count: activeCount),
      ),
    );
  }
}
