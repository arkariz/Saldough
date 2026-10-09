import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/theme/theme.dart';

/// Pilihan cepat berbentuk chip (komponen Chip, ADR-034): kategori di Catat,
/// filter di Riwayat, nominal cepat.
///
/// Tinggi 36px, area sentuh 48px, sudut piksel kecil. Latar `surface2`
/// (atau `surface` dengan [onBg] di atas `bg`); terpilih `brandSoft` +
/// teks `brandInk` dengan ikon centang menggantikan [icon].
class AppChip extends StatelessWidget {
  /// Membuat [AppChip].
  const AppChip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
    this.count,
    this.onBg = false,
    super.key,
  });

  /// Teks chip.
  final String label;

  /// Dipanggil saat diketuk; `null` menonaktifkan.
  final VoidCallback? onTap;

  /// Sedang terpilih.
  final bool selected;

  /// Ikon di depan label (Material Symbols 18px, atau ikon piksel kategori).
  final IconKey? icon;

  /// Jumlah setelah label ("Pengeluaran 24").
  final int? count;

  /// Chip di atas `bg`: latar `surface`.
  final bool onBg;

  /// Tinggi chip.
  static const height = 36.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ink = selected ? colors.brandInk : colors.ink;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(color: ink);
    final leading = selected ? IconKey.check : icon;
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.touch),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: ShapeDecoration(
                color: selected ? colors.brandSoft : (onBg ? colors.surface : colors.surface2),
                shape: const PixelCornerBorder.small(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    ExcludeSemantics(
                      child: AppIcon(
                        leading,
                        size: isPixelIcon(leading) ? AppSize.pixelIcon * 0.75 : 18,
                        color: ink,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  // Label memendek (elipsis) bila chip lebih lebar dari ruang yang ada.
                  Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style)),
                  if (count != null) ...[
                    const SizedBox(width: AppSpacing.space1),
                    Text(
                      '$count',
                      style: style?.copyWith(
                        color: selected ? colors.brandInk : colors.ink3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
