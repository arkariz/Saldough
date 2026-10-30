import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_button.dart';
import 'package:saldough/core/design_system/components/ds_flip_switcher.dart';
import 'package:saldough/core/design_system/components/ds_icon_tile.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_opacity.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Kartu saldo hero hijau hutan: label, saldo besar (bisa disembunyikan),
/// keterangan, dua kotak statistik, dan sampai dua tombol.
///
/// Komponen hanya menampilkan teks yang sudah diformat; menyembunyikan
/// nominal diatur pemanggil lewat [hidden] dan [onToggleHidden].
class DsHeroBalanceCard extends StatelessWidget {
  /// Membuat kartu saldo.
  const DsHeroBalanceCard({
    required this.label,
    required this.currencySymbol,
    required this.amount,
    required this.toggleLabel,
    this.labelIcon,
    this.hidden = false,
    this.hiddenMask = '••••••••',
    this.onToggleHidden,
    this.caption,
    this.stats = const [],
    this.actions = const [],
    super.key,
  });

  /// Label kepala kapital ("TOTAL SALDO").
  final String label;

  /// Ikon di depan [label].
  final IconData? labelIcon;

  /// Simbol mata uang ("Rp").
  final String currencySymbol;

  /// Nominal tanpa simbol ("14.850.000").
  final String amount;

  /// Saldo sedang disembunyikan.
  final bool hidden;

  /// Pengganti [amount] saat disembunyikan.
  final String hiddenMask;

  /// Dipanggil saat tombol mata diketuk; `null` menyembunyikan tombolnya.
  final VoidCallback? onToggleHidden;

  /// Label pembaca layar tombol mata ("Sembunyikan saldo").
  final String toggleLabel;

  /// Keterangan kecil di bawah saldo.
  final String? caption;

  /// Kotak statistik, paling banyak dua (`DsHeroStatTile`).
  final List<Widget> stats;

  /// Tombol, paling banyak dua (`DsButton.onHero`, `DsButton.onHeroTonal`).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.heroSurface,
        borderRadius: DsRadius.lgAll,
        border: Border.all(color: c.heroBorder),
      ),
      child: Stack(
        children: [
          Positioned(right: -32, top: -32, child: _Glow(color: c.heroGlow, size: 144)),
          Positioned(left: 80, bottom: -40, child: _Glow(color: c.heroAccent, size: 128)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (labelIcon != null) ...[
                      Icon(labelIcon, size: 15, color: c.heroAccent),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(label, style: ds.typography.pixelLabel.copyWith(color: c.onHeroMuted)),
                    ),
                    if (onToggleHidden != null)
                      DsIconButton.onHero(
                        icon: hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        label: toggleLabel,
                        onPressed: onToggleHidden,
                      ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(currencySymbol, style: ds.typography.pixelLabel.copyWith(fontSize: 14, color: c.heroAccent)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        // Balik 3D saat disembunyikan/ditampilkan; perubahan
                        // angka (hitung naik) tidak memicunya.
                        child: DsFlipSwitcher(
                          child: Text(
                            hidden ? hiddenMask : amount,
                            key: ValueKey(hidden),
                            style: ds.typography.pixelDisplay.copyWith(color: c.onHero),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(caption!, style: ds.typography.pixelCaption.copyWith(color: c.onHeroMuted)),
                ],
                if (stats.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(children: _spaced(stats, 8)),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(children: _spaced(actions, 8)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<Widget> _spaced(List<Widget> items, double gap) => [
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) SizedBox(width: gap),
      Expanded(child: items[i]),
    ],
  ];
}

/// Kotak statistik di kartu saldo hero (Masuk/Keluar).
class DsHeroStatTile extends StatelessWidget {
  /// Membuat kotak statistik.
  const DsHeroStatTile({required this.icon, required this.label, required this.value, this.income = true, super.key});

  /// Ikon panah.
  final IconData icon;

  /// Label kapital ("MASUK").
  final String label;

  /// Nominal yang sudah diformat.
  final String value;

  /// Nada pemasukan (hijau) atau pengeluaran (kuning).
  final bool income;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.heroTile,
        borderRadius: DsRadius.mdAll,
        border: Border.all(color: c.onHero.withValues(alpha: DsOpacity.heroHairline)),
      ),
      child: Row(
        children: [
          DsIconTile(
            icon: icon,
            size: DsIconTileSize.xs,
            tone: income ? DsIconTileTone.heroIncome : DsIconTileTone.heroExpense,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ds.typography.pixelCaption.copyWith(color: c.onHeroMuted)),
                Text(
                  value,
                  style: ds.typography.amountSm.copyWith(color: c.onHero),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: DsOpacity.glow),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
