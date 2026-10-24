import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_type.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Satu baris dompet di tab Dompet (prototipe `Dompet.dc.html`): tile ikon
/// piksel jenis dompet, nama, "■ Bank · 54%", dan saldo di kanan. Saldo
/// negatif ditulis bertanda minus tetap `ink` (FR-WAL-003). Diletakkan di
/// dalam `AppListCard` oleh pemanggil.
class WalletCard extends StatelessWidget {
  /// Membuat [WalletCard].
  const WalletCard({
    required this.wallet,
    required this.onTap,
    this.shareText,
    this.swatchColor,
    this.linked = false,
    super.key,
  });

  /// Dompet yang ditampilkan.
  final Wallet wallet;

  /// Dipanggil saat baris diketuk.
  final VoidCallback onTap;

  /// Bagian saldo dompet ini ("54%", "<1%"), atau `null`.
  final String? shareText;

  /// Warna dompet di kartu Sebaran saldo, ditulis sebagai penanda di depan
  /// subjudul; `null` = tanpa penanda (satu dompet, dompet nonaktif).
  final Color? swatchColor;

  /// Dompet ini sedang dipilih di donat Sebaran saldo (`tk-row.is-linked`):
  /// latar `surface2` dan garis `brand` 4px di kiri.
  final bool linked;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final type = walletTypeLabel(wallet.iconKey);
    final subtitle = [?type, ?shareText].join(' · ');
    final row = AppListRow(
      leading: AppIconTile(walletIconKey(wallet.iconKey)),
      title: wallet.name,
      wrapTitle: true,
      subtitle: subtitle.isEmpty ? null : subtitle,
      subtitleLeading: swatchColor == null ? null : WalletSwatch(swatchColor!),
      trailing: AppMoneyText(wallet.currentBalance),
      onTap: onTap,
    );
    return Opacity(
      opacity: wallet.isActive ? 1 : AppSize.disabledOpacity + 0.3,
      child: !linked
          ? row
          : DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface2,
                border: Border(left: BorderSide(color: colors.brand, width: 4)),
              ),
              child: row,
            ),
    );
  }
}

/// Penanda warna dompet 8px (`tk-swatch`).
class WalletSwatch extends StatelessWidget {
  /// Membuat [WalletSwatch].
  const WalletSwatch(this.color, {super.key});

  /// Warna dompet.
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(dimension: 8, child: ColoredBox(color: color));
}

/// Warna jenis dompet (tabel warna `cat-*` design system: Bank biru,
/// Tabungan amber, Tunai hijau, digital teal, Kartu cokelat).
TileTint _walletTint(String iconKey) => switch (walletIconKey(iconKey)) {
  IconKey.walletBank => TileTint.blue,
  IconKey.walletSavings => TileTint.amber,
  IconKey.walletCash => TileTint.green,
  IconKey.walletEwallet => TileTint.teal,
  IconKey.walletCard => TileTint.brown,
  _ => TileTint.slate,
};

/// Urutan warna cadangan bagi dompet kedua dan seterusnya dari jenis yang
/// sama.
const List<TileTint> _sparePalette = [
  TileTint.blue,
  TileTint.amber,
  TileTint.green,
  TileTint.teal,
  TileTint.brown,
  TileTint.orange,
  TileTint.purple,
  TileTint.rose,
  TileTint.indigo,
];

/// Warna tiap dompet di kartu Sebaran saldo (BalanceSpread: per dompet,
/// token `cat-*`, sama di bar, donat, legenda, dan penanda baris). Dompet
/// pertama tiap jenis memakai warna jenisnya; dompet sejenis berikutnya
/// mendapat warna cadangan pertama yang belum terpakai, urut [wallets].
/// Warna hanya pembeda, bukan status.
Map<String, Color> walletColors(AppColors colors, List<Wallet> wallets) {
  final used = <TileTint>{};
  final result = <String, Color>{};
  for (final wallet in wallets) {
    var tint = _walletTint(wallet.iconKey);
    if (used.contains(tint)) {
      tint = _sparePalette.firstWhere((c) => !used.contains(c), orElse: () => TileTint.slate);
    }
    used.add(tint);
    result[wallet.id] = colors.tile(tint).$2;
  }
  return result;
}

/// Bar sebaran saldo per dompet (BalanceSpread, ringkas): satu ruas per
/// dompet bersaldo positif, lebar sebanding saldonya, berjarak 2px, tinggi
/// 12px, tiap ruas minimal 3px supaya dompet kecil tetap terlihat. Dibaca
/// pembaca layar sebagai "Sebaran saldo: BCA 54%, …" oleh pemanggil.
class WalletSpreadBar extends StatelessWidget {
  /// Membuat [WalletSpreadBar].
  const WalletSpreadBar({required this.wallets, required this.colors, super.key});

  /// Dompet bersaldo positif, urutan tampil.
  final List<Wallet> wallets;

  /// Warna per `id` dompet dari [walletColors].
  final Map<String, Color> colors;

  static const double _gap = 2;
  static const double _minSegment = 3;

  @override
  Widget build(BuildContext context) {
    if (wallets.isEmpty) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: SizedBox(
          height: 12,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final widths = _widths(constraints.maxWidth - _gap * (wallets.length - 1));
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, w) in wallets.indexed) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    SizedBox(width: widths[i], child: ColoredBox(color: colors[w.id]!)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Lebar tiap ruas: sebanding saldo, ruas di bawah [_minSegment] dinaikkan
  /// ke batas itu dan sisanya dibagi ulang ke ruas lain.
  List<double> _widths(double available) {
    final total = wallets.fold<int>(0, (sum, w) => sum + w.currentBalance);
    final small = <int>{
      for (final (i, w) in wallets.indexed)
        if (available * w.currentBalance / total < _minSegment) i,
    };
    final rest = available - small.length * _minSegment;
    final restTotal = [
      for (final (i, w) in wallets.indexed)
        if (!small.contains(i)) w.currentBalance,
    ].fold<int>(0, (a, b) => a + b);
    return [
      for (final (i, w) in wallets.indexed)
        if (small.contains(i) || restTotal == 0) _minSegment else rest * w.currentBalance / restTotal,
    ];
  }
}
