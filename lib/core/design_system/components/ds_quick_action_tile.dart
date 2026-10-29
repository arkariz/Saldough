import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_pressable.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';

/// Tile aksi cepat: kartu kecil berisi tile ikon dan label piksel di
/// bawahnya. Biasanya disusun empat kolom berjarak 8.
class DsQuickActionTile extends StatelessWidget {
  /// Membuat tile aksi cepat.
  const DsQuickActionTile({required this.tile, required this.label, required this.onPressed, super.key});

  /// Tile ikon (`DsIconTile` ukuran md).
  final Widget tile;

  /// Label tindakan.
  final String label;

  /// Dipanggil saat diketuk.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return DsPressable(
      onPressed: onPressed,
      pressedScale: DsMotion.pressScaleTile,
      builder: (context, pressed) => AnimatedContainer(
        duration: DsMotion.standard,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: ds.elevation.card.decoration().copyWith(color: pressed ? ds.colors.surfaceContainerLow : null),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            tile,
            const SizedBox(height: 6),
            Text(
              label,
              style: ds.typography.pixelLabel.copyWith(color: ds.colors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
