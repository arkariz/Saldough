import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Tile ikon `brand-soft` untuk Plus (`tk-tile--brandsoft`): latar `brandSoft`,
/// ikon `brandInk`, sudut piksel kecil. Dipakai paywall, layar berhasil, dan
/// kartu Plus; ikonnya dekoratif.
class PlusTile extends StatelessWidget {
  /// Membuat [PlusTile].
  const PlusTile(this.icon, {this.size = 48, super.key});

  /// Ikon di dalam tile.
  final IconKey icon;

  /// Sisi tile.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: colors.brandSoft,
          shape: const PixelCornerBorder.small(),
        ),
        child: AppIcon(icon, color: colors.brandInk),
      ),
    );
  }
}
