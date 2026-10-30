import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_card.dart';
import 'package:saldough/core/design_system/components/ds_icon_tile.dart';
import 'package:saldough/core/design_system/ds_theme.dart';

/// Banner satu baris: tile ikon pekat, eyebrow piksel kapital + pesan, dan
/// satu tombol ringkas di kanan.
class DsInlineBanner extends StatelessWidget {
  /// Membuat banner.
  const DsInlineBanner({required this.icon, required this.message, this.eyebrow, this.action, super.key});

  /// Ikon tile.
  final IconData icon;

  /// Label kecil di atas pesan, ditulis kapital oleh pemanggil.
  final String? eyebrow;

  /// Pesan satu baris (terpotong bila panjang).
  final String message;

  /// Tombol di kanan (`DsButton.compact`).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DsCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          DsIconTile(icon: icon, tone: DsIconTileTone.solid, size: DsIconTileSize.sm),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) Text(eyebrow!, style: ds.typography.pixelCaption.copyWith(color: c.actionPrimary)),
                Text(
                  message,
                  style: ds.typography.bodySm.copyWith(fontSize: 12, color: c.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}
