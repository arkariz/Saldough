import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Tombol solid bergaris tepi tebal dengan bayangan keras offset.
///
/// Warna bawaan memakai `colorScheme.primary`. Pakai [color] untuk varian
/// lain, misalnya [AppColorsExtension.expense] untuk aksi destruktif
/// (hapus pos, batalkan).
///
/// Saat ditekan, bayangan ditarik ke 0 dan tombol bergeser sejauh offset
/// bayangannya ke kanan-bawah — efek "ditekan" komik, pengganti splash
/// Material yang sengaja dimatikan secara global (ADR-0006, UX-32). Dipakai
/// [Listener] (bukan [GestureDetector]) supaya hanya mengamati status
/// tekan tanpa ikut merebut gestur dari [ElevatedButton] di dalamnya.
class AppButton extends StatefulWidget {
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
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fill = widget.color ?? Theme.of(context).colorScheme.primary;
    final isDisabled = widget.onPressed == null;
    final leadingIcon = widget.icon;
    final pressed = _pressed && !isDisabled;
    final style = ElevatedButton.styleFrom(
      backgroundColor: isDisabled ? colors.textMuted.withValues(alpha: 0.3) : fill,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.smAll,
        side: BorderSide(color: colors.edge, width: AppBorder.thick),
      ),
    );

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        transform: Matrix4.translationValues(
          pressed ? AppElevation.sm : 0,
          pressed ? AppElevation.sm : 0,
          0,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.smAll,
          boxShadow: isDisabled
              ? null
              : AppElevation.hardShadow(colors.edge, offset: pressed ? 0 : AppElevation.sm),
        ),
        child: leadingIcon != null
            ? ElevatedButton.icon(
                onPressed: widget.onPressed,
                icon: Icon(leadingIcon, size: 18),
                label: Text(widget.label),
                style: style,
              )
            : ElevatedButton(
                onPressed: widget.onPressed,
                style: style,
                child: Text(widget.label),
              ),
      ),
    );
  }
}
