import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_type.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Satu baris dompet di tab Dompet (prototipe `Dompet.dc.html`): tile ikon
/// piksel jenis dompet, nama, "Bank · 54%", dan saldo di kanan. Saldo
/// negatif ditulis bertanda minus tetap `ink` (FR-WAL-003). Diletakkan di
/// dalam `AppListCard` oleh pemanggil.
class WalletCard extends StatelessWidget {
  /// Membuat [WalletCard].
  const WalletCard({required this.wallet, required this.onTap, this.sharePercent, super.key});

  /// Dompet yang ditampilkan.
  final Wallet wallet;

  /// Dipanggil saat baris diketuk.
  final VoidCallback onTap;

  /// Bagian saldo dompet ini terhadap total saldo aktif, atau `null`.
  final int? sharePercent;

  @override
  Widget build(BuildContext context) {
    final type = walletTypeLabel(wallet.iconKey);
    final subtitle = [?type, if (sharePercent != null) '$sharePercent%'].join(' · ');
    return Opacity(
      opacity: wallet.isActive ? 1 : AppSize.disabledOpacity + 0.3,
      child: AppListRow(
        leading: AppIconTile(walletIconKey(wallet.iconKey)),
        title: wallet.name,
        wrapTitle: true,
        subtitle: subtitle.isEmpty ? null : subtitle,
        trailing: AppMoneyText(wallet.currentBalance),
        onTap: onTap,
      ),
    );
  }
}

/// Warna segmen bar sebaran per jenis dompet (tabel warna `cat-*` design
/// system: Bank biru, Tabungan amber, Tunai hijau, digital teal, Kartu
/// cokelat).
Color walletSpreadColor(AppColors colors, String iconKey) => switch (walletIconKey(iconKey)) {
  IconKey.walletBank => colors.catBlue,
  IconKey.walletSavings => colors.catAmber,
  IconKey.walletCash => colors.catGreen,
  IconKey.walletEwallet => colors.catTeal,
  IconKey.walletCard => colors.catBrown,
  _ => colors.catSlate,
};

/// Bar sebaran saldo per dompet (ADR-034 §4): satu segmen per dompet
/// bersaldo positif, lebar sebanding persennya, berjarak 2px, tinggi 12px.
/// Dibaca pembaca layar sebagai daftar "BCA 54 persen, …".
class WalletSpreadBar extends StatelessWidget {
  /// Membuat [WalletSpreadBar].
  const WalletSpreadBar({required this.wallets, required this.shares, super.key});

  /// Dompet aktif, urutan tampil.
  final List<Wallet> wallets;

  /// Persen per `id` dompet dari `walletShares`.
  final Map<String, int> shares;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final shown = [
      for (final w in wallets)
        if ((shares[w.id] ?? 0) > 0) w,
    ];
    if (shown.isEmpty) return const SizedBox.shrink();
    return Semantics(
      label: [for (final w in shown) '${w.name} ${shares[w.id]}%'].join(', '),
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (final (i, w) in shown.indexed) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    flex: shares[w.id]!,
                    child: ColoredBox(color: walletSpreadColor(colors, w.iconKey)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
