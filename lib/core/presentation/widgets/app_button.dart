import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Tombol solid bergaris tepi tebal dengan bayangan keras offset.
///
/// Warna bawaan memakai `colorScheme.primary`. Pakai [color] untuk varian
/// lain, misalnya [AppColorsExtension.expense] untuk aksi destruktif
/// (hapus pos, batalkan).
class AppButton extends StatelessWidget {
  /// Membuat [AppButton] dengan [label] dan [onPressed].
  const AppButton({
    required this.label,
    required this.onPressed,
    this.color,
    this.icon,
    super.key,
  });

  /// Teks tombol.
  final String label;

  /// Dipanggil saat tombol ditekan. `null` menonaktifkan tombol.
  final VoidCallback? onPressed;

  /// Warna isian tombol. Bawaan `colorScheme.primary`.
  final Color? color;

  /// Ikon opsional di depan [label].
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fill = color ?? Theme.of(context).colorScheme.primary;
    final isDisabled = onPressed == null;
    final leadingIcon = icon;
    final style = ElevatedButton.styleFrom(
      backgroundColor: isDisabled ? colors.textMuted.withValues(alpha: 0.3) : fill,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.smAll,
        side: BorderSide(color: colors.edge, width: AppBorder.thick),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.smAll,
        boxShadow: isDisabled ? null : AppElevation.hardShadow(colors.edge, offset: AppElevation.sm),
      ),
      child: leadingIcon != null
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(leadingIcon, size: 18),
              label: Text(label),
              style: style,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: style,
              child: Text(label),
            ),
    );
  }
}
