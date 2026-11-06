import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Nada [DsPill].
enum DsPillTone {
  /// Hijau lembut: aktif, selesai.
  positive,

  /// Kabut netral: hitungan, keterangan.
  neutral,

  /// Kuning perhatian.
  warning,

  /// Merah: perlu tindakan.
  danger,
}

/// Pil status bulat penuh: titik atau ikon di depan, [label], dan ikon di
/// belakang (mis. panah). Untuk status dan hitungan di baris kartu; label
/// pendek (`badge` 6px tetap untuk tag kategori, KT-DS4).
class DsPill extends StatelessWidget {
  /// Membuat pil.
  const DsPill({
    required this.label,
    this.tone = DsPillTone.neutral,
    this.dot = false,
    this.icon,
    this.trailingIcon,
    super.key,
  });

  /// Teks pil.
  final String label;

  /// Nada warna.
  final DsPillTone tone;

  /// Titik kecil di depan label.
  final bool dot;

  /// Ikon di depan label (menggantikan titik bila keduanya ada).
  final IconData? icon;

  /// Ikon di belakang label.
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final (Color fill, Color ink) = switch (tone) {
      DsPillTone.positive => (c.incomeContainer, c.onIncomeContainer),
      DsPillTone.neutral => (c.surfaceSunken, c.textSecondary),
      DsPillTone.warning => (c.warningContainer, c.onWarningContainer),
      DsPillTone.danger => (c.errorContainer, c.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fill, borderRadius: DsRadius.fullAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: ink), const SizedBox(width: 4)],
          if (icon == null && dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ds.typography.labelMd.copyWith(color: ink, letterSpacing: 0),
            ),
          ),
          if (trailingIcon != null) ...[const SizedBox(width: 4), Icon(trailingIcon, size: 14, color: ink)],
        ],
      ),
    );
  }
}
