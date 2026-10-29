import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/color/ds_color_scheme.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_opacity.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Ukuran [DsIconTile] (`components.md` bagian Icon tile).
enum DsIconTileSize {
  /// 24px bulat, ikon 14: kotak statistik kartu saldo.
  xs(24, 14),

  /// 36px, ikon 20: banner misi.
  sm(36, 20),

  /// 40px, ikon 19: aksi cepat, baris transaksi.
  md(40, 19),

  /// 48px, isi 32: maskot.
  lg(48, 32);

  const DsIconTileSize(this.side, this.iconSize);

  /// Sisi kotak.
  final double side;

  /// Ukuran ikon atau isi.
  final double iconSize;
}

/// Nada warna [DsIconTile].
enum DsIconTileTone {
  /// Kabut netral bergaris rambut.
  neutral,

  /// Sage pemasukan.
  income,

  /// Biru info.
  info,

  /// Kuning perhatian.
  warning,

  /// Hijau pekat berikon putih.
  solid,

  /// Pemasukan di atas kartu saldo hero.
  heroIncome,

  /// Pengeluaran di atas kartu saldo hero.
  heroExpense,
}

/// Kotak berisi ikon (atau ilustrasi kecil) dengan latar bernada.
///
/// Pakai [DsIconTile.category] untuk warna kategori. Ikon dekoratif:
/// makna dibawa teks di sebelahnya, jadi tidak dibacakan.
class DsIconTile extends StatelessWidget {
  /// Tile berikon dengan [tone].
  const DsIconTile({
    required IconData this.icon,
    this.tone = DsIconTileTone.neutral,
    this.size = DsIconTileSize.md,
    super.key,
  }) : child = null,
       category = null;

  /// Tile berwarna kategori [category].
  const DsIconTile.category({required IconData this.icon, required this.category, this.size = DsIconTileSize.md, super.key})
    : child = null,
      tone = DsIconTileTone.neutral;

  /// Tile berisi widget bebas (ilustrasi maskot), latar netral.
  const DsIconTile.child({required this.child, this.size = DsIconTileSize.lg, super.key})
    : icon = null,
      category = null,
      tone = DsIconTileTone.neutral;

  /// Ikon.
  final IconData? icon;

  /// Isi bebas pengganti [icon].
  final Widget? child;

  /// Nada warna.
  final DsIconTileTone tone;

  /// Pasangan warna kategori; menimpa [tone].
  final DsColorPair? category;

  /// Ukuran.
  final DsIconTileSize size;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final (Color fill, Color ink, Color? border) = category != null
        ? (category!.container, category!.color, null)
        : switch (tone) {
            DsIconTileTone.neutral => (c.surfaceSunken, c.textSecondary, c.outlineSubtle),
            DsIconTileTone.income => (c.incomeContainer, c.income, null),
            DsIconTileTone.info => (c.infoContainer, c.info, null),
            DsIconTileTone.warning => (c.warningContainer, c.onWarningContainer, null),
            DsIconTileTone.solid => (c.actionPrimary, c.onActionPrimary, null),
            DsIconTileTone.heroIncome => (c.heroAccent.withValues(alpha: DsOpacity.heroTileTint), c.onHeroMuted, null),
            DsIconTileTone.heroExpense => (
              c.heroAccentWarm.withValues(alpha: DsOpacity.heroTileTint),
              c.heroAccentWarm,
              null,
            ),
          };
    final round = size == DsIconTileSize.xs;
    return ExcludeSemantics(
      child: Container(
        width: size.side,
        height: size.side,
        alignment: Alignment.center,
        padding: child != null ? const EdgeInsets.all(4) : null,
        decoration: BoxDecoration(
          color: fill,
          shape: round ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: round ? null : DsRadius.mdAll,
          border: border == null ? null : Border.all(color: border),
        ),
        child: child ?? Icon(icon, size: size.iconSize, color: ink),
      ),
    );
  }
}
