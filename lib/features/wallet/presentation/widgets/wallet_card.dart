import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_type.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Penanda warna dompet bulat 8px.
class WalletSwatch extends StatelessWidget {
  /// Membuat [WalletSwatch].
  const WalletSwatch(this.color, {super.key});

  /// Warna dompet.
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 8,
    child: DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
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
/// dompet bersaldo positif, lebar sebanding saldonya, berbentuk pil berjarak
/// 3px di atas lintasan abu, tinggi 10px, tiap ruas minimal 6px supaya
/// dompet kecil tetap terlihat. Dibaca
/// pembaca layar sebagai "Sebaran saldo: BCA 54%, …" oleh pemanggil.
class WalletSpreadBar extends StatelessWidget {
  /// Membuat [WalletSpreadBar].
  const WalletSpreadBar({required this.wallets, required this.colors, super.key});

  /// Dompet bersaldo positif, urutan tampil.
  final List<Wallet> wallets;

  /// Warna per `id` dompet dari [walletColors].
  final Map<String, Color> colors;

  static const double _gap = 3;
  static const double _minSegment = 6;

  @override
  Widget build(BuildContext context) {
    if (wallets.isEmpty) return const SizedBox.shrink();
    final track = context.ds.colors.surfaceContainerHigh;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(color: track, borderRadius: DsRadius.fullAll),
        child: SizedBox(
          height: 10,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final widths = _widths(constraints.maxWidth - _gap * (wallets.length - 1));
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, w) in wallets.indexed) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    SizedBox(
                      width: widths[i],
                      // Tiap ruas pil sendiri berkilap tipis di atasnya.
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: DsRadius.fullAll,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color.lerp(colors[w.id], Colors.white, 0.28)!, colors[w.id]!],
                          ),
                        ),
                      ),
                    ),
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

/// Warna tiap dompet di kartu Sebaran saldo, versi v2: pasangan kategori
/// preset aktif. Aturan sama dengan [walletColors] (dompet pertama tiap jenis
/// memakai warna jenisnya; yang sejenis berikutnya warna cadangan pertama
/// yang belum terpakai).
Map<String, Color> walletColorsDs(DsColorScheme scheme, List<Wallet> wallets) {
  final cats = scheme.categories;
  // Urutan: bank, tabungan, tunai, digital, kartu, lalu cadangan.
  final palette = [
    cats.blue,
    cats.amber,
    cats.green,
    cats.teal,
    cats.brown,
    cats.orange,
    cats.purple,
    cats.rose,
    cats.indigo,
  ];
  int typeIndex(String iconKey) => switch (walletIconKey(iconKey)) {
    IconKey.walletBank => 0,
    IconKey.walletSavings => 1,
    IconKey.walletCash => 2,
    IconKey.walletEwallet => 3,
    IconKey.walletCard => 4,
    _ => -1,
  };
  final used = <int>{};
  final result = <String, Color>{};
  for (final wallet in wallets) {
    var index = typeIndex(wallet.iconKey);
    if (index < 0 || used.contains(index)) {
      index = [for (var i = 0; i < palette.length; i++) i].firstWhere((i) => !used.contains(i), orElse: () => -1);
    }
    if (index >= 0) used.add(index);
    result[wallet.id] = index < 0 ? scheme.categories.slate.color : palette[index].color;
  }
  return result;
}

/// Satu dompet sebagai kartu bento (acuan Dompet v2): tile ikon clay jenis
/// dompet, lencana jenis, nama, saldo, dan persen porsi dengan penanda warna.
/// Saldo mengikuti sembunyikan nominal; saldo negatif bertanda minus.
class WalletBentoCard extends StatelessWidget {
  /// Membuat [WalletBentoCard].
  const WalletBentoCard({
    required this.wallet,
    required this.onTap,
    this.shareText,
    this.swatchColor,
    this.linked = false,
    super.key,
  });

  /// Dompet yang ditampilkan.
  final Wallet wallet;

  /// Dipanggil saat kartu diketuk (membuka rincian).
  final VoidCallback onTap;

  /// Bagian saldo ("54%", "<1%"), atau `null`.
  final String? shareText;

  /// Warna dompet di kartu Sebaran saldo.
  final Color? swatchColor;

  /// Dompet ini sedang dipilih di donat Sebaran saldo.
  final bool linked;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final type = walletTypeLabel(wallet.iconKey);
    final asset = ClayIcons.forIcon(walletIconKey(wallet.iconKey)) ?? ClayIcons.walletNav;
    final tile = DsIconTile.asset(asset: asset);
    final badges = Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (type != null) DsBadge(label: type, tone: DsBadgeTone.neutral),
        if (shareText != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (swatchColor != null) ...[WalletSwatch(swatchColor!), const SizedBox(width: 4)],
              Text(shareText!, style: ds.typography.labelMd.copyWith(color: c.textMuted, fontSize: 11)),
            ],
          ),
      ],
    );
    // Tanpa elipsis: nama panjang membungkus, tidak dipotong.
    final name = Text(
      wallet.name,
      style: ds.typography.titleMd.copyWith(fontSize: 15),
    );
    final amount = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: AppMoneyText(wallet.currentBalance, size: MoneySize.large),
    );
    return Opacity(
      opacity: wallet.isActive ? 1 : 0.6,
      child: Semantics(
        button: true,
        label: wallet.name,
        child: DsPressable(
          onPressed: onTap,
          dimWhenDisabled: false,
          builder: (context, _) => AnimatedContainer(
            duration: DsMotion.reduced(context) ? Duration.zero : DsMotion.standard,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: linked ? c.actionPrimary.withValues(alpha: 0.06) : c.surfaceCard,
              borderRadius: DsRadius.xlAll,
              border: Border.all(color: linked ? c.actionPrimary : c.outlineSubtle, width: linked ? 1.5 : 1),
              boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tile,
                const SizedBox(height: 12),
                name,
                const SizedBox(height: 4),
                amount,
                const SizedBox(height: 6),
                badges,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
