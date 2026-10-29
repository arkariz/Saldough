import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_card.dart';
import 'package:saldough/core/design_system/components/ds_icon_tile.dart';
import 'package:saldough/core/design_system/components/ds_segment_meter.dart';
import 'package:saldough/core/design_system/ds_theme.dart';

/// Kartu mood maskot: ilustrasi tanuki, judul + badge, meter kesehatan,
/// dan satu baris keterangan.
class DsMascotCard extends StatelessWidget {
  /// Membuat kartu mood.
  const DsMascotCard({
    required this.mascot,
    required this.title,
    required this.meterValue,
    required this.meterLabel,
    this.badge,
    this.note,
    this.noteIcon,
    this.statusDot = true,
    this.onTap,
    super.key,
  });

  /// Ilustrasi maskot (32px).
  final Widget mascot;

  /// Judul ("Mood: Santai & Makmur").
  final String title;

  /// Badge di kanan judul.
  final Widget? badge;

  /// Isi meter kesehatan, 0–1.
  final double meterValue;

  /// Label pembaca layar meter.
  final String meterLabel;

  /// Keterangan satu baris.
  final String? note;

  /// Ikon keterangan.
  final IconData? noteIcon;

  /// Titik status hijau di pojok ilustrasi.
  final bool statusDot;

  /// Dipanggil saat kartu diketuk.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DsCard(
      onTap: onTap,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              DsIconTile.child(child: mascot),
              if (statusDot)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.income,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surfaceCard, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: ds.typography.pixelAmount.copyWith(color: c.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[const SizedBox(width: 4), badge!],
                  ],
                ),
                const SizedBox(height: 6),
                DsSegmentMeter(value: meterValue, semanticLabel: meterLabel, variant: DsSegmentMeterVariant.health),
                if (note != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (noteIcon != null) ...[
                        Icon(noteIcon, size: 14, color: c.actionPrimary),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          note!,
                          style: ds.typography.bodySm.copyWith(fontSize: 12, color: c.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
