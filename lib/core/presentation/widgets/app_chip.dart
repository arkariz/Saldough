import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Chip bergaris tepi tebal, dipakai untuk badge status (`needsReview`),
/// label pilihan cepat, dan tag insidental/tetap.
///
/// [selected] menukar isian jadi [color] penuh (bawaan
/// `colorScheme.primary`); tidak terpilih menampilkan garis tepi saja.
class AppChip extends StatelessWidget {
  /// Membuat [AppChip] dengan [label].
  const AppChip({
    required this.label,
    this.selected = false,
    this.color,
    this.onTap,
    super.key,
  });

  /// Teks chip.
  final String label;

  /// Apakah chip tampil terisi (dipilih) atau hanya bergaris tepi.
  final bool selected;

  /// Warna isian saat [selected]. Bawaan `colorScheme.primary`.
  final Color? color;

  /// Dipanggil saat chip diketuk. `null` membuat chip non-interaktif.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fill = color ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? fill : Colors.transparent,
          borderRadius: AppRadius.fullAll,
          border: Border.all(color: colors.edge, width: 2),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? _onFill(fill, colors) : colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }

  Color _onFill(Color fill, AppColorsExtension colors) =>
      fill == colors.needsReview ? colors.onNeedsReview : colors.background;
}
