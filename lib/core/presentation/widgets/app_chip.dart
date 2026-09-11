import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Chip bergaris tepi tebal, dipakai untuk badge status (`needsReview`),
/// label pilihan cepat, dan tag insidental/tetap.
///
/// [selected] menukar isian jadi [color] penuh (bawaan
/// `colorScheme.primary`); tidak terpilih menampilkan garis tepi saja.
///
/// Area sentuhnya minimum 44px (UX-31) walau tampilan visualnya tetap
/// sekecil semula — chip bukan elemen dekoratif, ia satu-satunya kontrol
/// untuk memilih sumber pemasukan/anggaran/kartu di beberapa layar. Saat
/// ditekan, chip menyusut sedikit (bukan splash Material yang sengaja
/// dimatikan secara global, ADR-0006) — umpan balik tekan tanpa mengubah
/// tampilan diamnya (UX-32).
class AppChip extends StatefulWidget {
  /// Membuat [AppChip] dengan [label].
  const AppChip({
    required this.label,
    this.selected = false,
    this.color,
    this.onTap,
    this.shout = false,
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

  /// True untuk badge status pendek bergaya stiker komik (`AppTheme.shout`,
  /// Bangers) — mis. "Perlu ditinjau", "Nonaktif". Bawaan `false` (Space
  /// Grotesk): Bangers tidak cocok untuk label yang bisa panjang/berulang
  /// seperti pilihan sumber atau nama kartu (ADR-0006 — angka/label
  /// panjang tetap grotesk, hanya badge stiker pendek yang boleh Bangers).
  /// Lihat `docs/04-planning/UX_REVIEW_FIXES.md` item UX-27.
  final bool shout;

  @override
  State<AppChip> createState() => _AppChipState();
}

class _AppChipState extends State<AppChip> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  Color _onFill(Color fill, AppColorsExtension colors) =>
      fill == colors.needsReview ? colors.onNeedsReview : colors.background;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fill = widget.color ?? Theme.of(context).colorScheme.primary;
    final textColor = widget.selected ? _onFill(fill, colors) : colors.textPrimary;
    final pressed = _pressed && widget.onTap != null;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Center(
          child: AnimatedScale(
            duration: AppDurations.fast,
            scale: pressed ? 0.94 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: widget.selected ? fill : Colors.transparent,
                borderRadius: AppRadius.fullAll,
                border: Border.all(color: colors.edge, width: AppBorder.thick),
              ),
              child: Text(
                widget.label,
                style: widget.shout
                    ? AppTheme.shout(color: textColor)
                    : Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
