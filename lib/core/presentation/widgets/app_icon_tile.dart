import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/theme/theme.dart';

/// Pasangan warna tile `cat-*` (design system bagian Warna), plus `info`
/// untuk transfer.
enum TileTint {
  /// `cat-orange`: Makan & Minum.
  orange,

  /// `cat-green`: Belanja Harian, Gaji; dompet Tunai.
  green,

  /// `cat-blue`: Transportasi; dompet Bank.
  blue,

  /// `cat-purple`: Tagihan.
  purple,

  /// `cat-teal`: Pulsa & Internet; dompet digital.
  teal,

  /// `cat-rose`: Kesehatan, Hadiah.
  rose,

  /// `cat-amber`: Belanja, Bonus; dompet Tabungan.
  amber,

  /// `cat-indigo`: Pendidikan, Hiburan, Freelance.
  indigo,

  /// `cat-brown`: Keluarga, Donasi; dompet Kartu.
  brown,

  /// `cat-slate`: Lainnya dan Tanpa kategori.
  slate,

  /// `info`: transfer.
  info,
}

/// Warna latar dan ikon untuk [TileTint].
extension TileTintColors on AppColors {
  /// `(latar, ikon)` untuk [tint].
  (Color, Color) tile(TileTint tint) => switch (tint) {
    TileTint.orange => (catOrangeBg, catOrange),
    TileTint.green => (catGreenBg, catGreen),
    TileTint.blue => (catBlueBg, catBlue),
    TileTint.purple => (catPurpleBg, catPurple),
    TileTint.teal => (catTealBg, catTeal),
    TileTint.rose => (catRoseBg, catRose),
    TileTint.amber => (catAmberBg, catAmber),
    TileTint.indigo => (catIndigoBg, catIndigo),
    TileTint.brown => (catBrownBg, catBrown),
    TileTint.slate => (catSlateBg, catSlate),
    TileTint.info => (infoSoft, info),
  };
}

/// Warna tile bawaan untuk kunci tanpa ikon piksel (README design system
/// bagian Ikon); kunci lain yang jatuh ke Material Symbols memakai
/// [TileTint.slate].
const Map<IconKey, TileTint> _symbolTints = {
  IconKey.categoryFamily: TileTint.brown,
  IconKey.categoryDonation: TileTint.brown,
  IconKey.categoryBonus: TileTint.amber,
  IconKey.categoryGift: TileTint.rose,
  IconKey.categoryOther: TileTint.slate,
};

/// Tile ikon kategori, dompet, atau jenis transaksi (komponen IconTile).
///
/// Dua varian, dipilih dari [icon]:
/// - ikon piksel: ikon 32px (64px bila tile ≥ 80px) di tile netral
///   `surface2`, skala 1:1 supaya piksel tetap tajam;
/// - Material Symbols (kategori tanpa ikon piksel, B-22): ikon `cat-*` di
///   tile `cat-*-bg`, warna dari [tint] atau tabel bawaan.
///
/// Sudut piksel kecil (`pixel-step-sm`). Ukuran `size-tile` (40) di baris,
/// 32 di chip dan baris padat, 48 di kepala rincian.
class AppIconTile extends StatelessWidget {
  /// Membuat [AppIconTile] untuk [icon].
  const AppIconTile(this.icon, {this.size = AppSize.tile, this.tint, this.selected = false, super.key});

  /// Ikon yang dibawa tile.
  final IconKey icon;

  /// Sisi tile.
  final double size;

  /// Warna tile varian Material Symbols; diabaikan untuk ikon piksel.
  final TileTint? tint;

  /// Terpilih (pemilih kategori Catat): latar `brandSoft` dengan garis
  /// dalam `brand` 2px.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final pixel = isPixelIcon(icon);
    final (background, ink) = pixel
        ? (colors.surface2, colors.ink)
        : colors.tile(tint ?? _symbolTints[icon] ?? TileTint.slate);
    final glyph = pixel
        ? (size >= 80 ? 64.0 : AppSize.pixelIcon)
        : (size >= 40 ? AppSize.icon : AppSize.iconSm);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        decoration: ShapeDecoration(
          color: background,
          shape: const PixelCornerBorder.small(),
        ),
        child: AppIcon(icon, size: glyph, color: ink),
      ),
    );
  }
}
