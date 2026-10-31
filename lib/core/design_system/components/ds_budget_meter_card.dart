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
    this.leading,
    this.badge,
    this.total,
    this.remaining,
    this.tone = DsMeterTone.normal,
    this.breathing = false,
    this.footer = const [],
    this.onTap,
    super.key,
  });

  /// Judul kartu.
  final String title;

  /// Ikon 17px di depan judul.
  final IconData? icon;

  /// Pengganti [icon] berupa widget bebas (mis. ikon clay 28px).
  final Widget? leading;

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

  /// Segmen meter bernapas dan berkilau; pakai hanya saat hampir habis.
  final bool breathing;

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
          // `Wrap`: pada skala teks besar badge turun ke baris sendiri, bukan
          // memeras judul per kata.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 8)]
                  else if (icon != null) ...[Icon(icon, size: 17, color: c.secondary), const SizedBox(width: 6)],
                  Flexible(
                    child: Text(
                      title,
                      style: ds.typography.titleMd.copyWith(fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 10),
          // `Wrap`: pada skala teks besar sisa turun ke baris sendiri, bukan
          // meluap atau memotong nominal terpakai.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            runSpacing: 2,
            children: [
              Row(
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
              if (remaining != null)
                Text(remaining!, style: ds.typography.amountSm.copyWith(fontSize: 12, color: remainingColor)),
            ],
          ),
          const SizedBox(height: 8),
          DsSegmentMeter(value: value, semanticLabel: meterLabel, tone: tone, breathing: breathing),
          if (footer.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: footer.length == 1 ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
              children: [
                for (final label in footer) Text(label, style: ds.typography.pixelCaption.copyWith(color: c.textMuted)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
