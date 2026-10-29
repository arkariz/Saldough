import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_card.dart';
import 'package:saldough/core/design_system/components/ds_segment_meter.dart';
import 'package:saldough/core/design_system/ds_theme.dart';

/// Kartu meter anggaran: judul + badge, terpakai / total + sisa, meter
/// tersegmen, dan tiga label kaki.
class DsBudgetMeterCard extends StatelessWidget {
  /// Membuat kartu meter.
  const DsBudgetMeterCard({
    required this.title,
    required this.spent,
    required this.value,
    required this.meterLabel,
    this.icon,
    this.badge,
    this.total,
    this.remaining,
    this.tone = DsMeterTone.normal,
    this.footer = const [],
    this.onTap,
    super.key,
  });

  /// Judul kartu.
  final String title;

  /// Ikon 17px di depan judul.
  final IconData? icon;

  /// Badge di kanan judul.
  final Widget? badge;

  /// Nominal terpakai yang sudah diformat.
  final String spent;

  /// Batas, ditampilkan sebagai "/ total".
  final String? total;

  /// Sisa ("Sisa Rp 65.000"), di kanan.
  final String? remaining;

  /// Bagian terpakai, 0–1.
  final double value;

  /// Label pembaca layar meter.
  final String meterLabel;

  /// Warna meter dan sisa.
  final DsMeterTone tone;

  /// Label kaki (awal, tengah, akhir), sampai tiga.
  final List<String> footer;

  /// Dipanggil saat kartu diketuk.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final remainingColor = switch (tone) {
      DsMeterTone.normal => c.income,
      DsMeterTone.warning => c.warning,
      DsMeterTone.danger => c.error,
    };
    return DsCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 17, color: c.secondary), const SizedBox(width: 6)],
              Expanded(
                child: Text(
                  title,
                  style: ds.typography.titleMd.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[const SizedBox(width: 6), badge!],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Terpakai + batas mendapat ruang lebih; sisa mengalah lebih dulu.
              Flexible(
                flex: 3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(spent, style: ds.typography.amount),
                    if (total != null) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '/ ${total!}',
                          style: ds.typography.bodySm.copyWith(fontSize: 12, color: c.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (remaining != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: Text(
                    remaining!,
                    style: ds.typography.amountSm.copyWith(fontSize: 12, color: remainingColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          DsSegmentMeter(value: value, semanticLabel: meterLabel, tone: tone),
          if (footer.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: footer.length == 1 ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
              children: [
                for (final label in footer)
                  Text(label, style: ds.typography.pixelCaption.copyWith(color: c.textMuted)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
