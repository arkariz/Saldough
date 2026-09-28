import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Tingkat penekanan sebuah [AppButton] (ADR-020 §3.1).
enum AppButtonVariant {
  /// Isian penuh, garis tepi 2px, bayangan keras interaktif. Aksi utama
  /// layar/lembar -- paling banyak SATU per layar.
  primary,

  /// Latar kartu, garis tepi 2px, TANPA bayangan (elevasi tingkat 0
  /// ADR-015). Aksi pendamping, termasuk aksi destruktif di luar dialog
  /// konfirmasi (teks [AppColorsExtension.expense], bukan isian merah).
  secondary,

  /// Tautan teks beraksen tanpa bingkai maupun bayangan (pola
  /// `HomeTextLink`). Aksi paling ringan, mis. "Lihat semua".
  tertiary,
}

/// Tombol dengan tiga tingkat penekanan (ADR-020) di atas bahasa visual
/// ADR-015 (bayangan keras offset, garis tepi tebal untuk [AppButtonVariant.primary]
/// dan [AppButtonVariant.secondary]).
///
/// Bawaan [AppButtonVariant.primary] memakai `colorScheme.primary`. Pakai
/// [color] untuk varian primary lain, misalnya
/// [AppColorsExtension.expense] untuk aksi destruktif **di dalam dialog
/// konfirmasi** -- di luar dialog, aksi destruktif memakai
/// [AppButton.secondary] dengan [textColor] `expense` (ADR-020 §3.1).
///
/// Saat ditekan, [AppButtonVariant.primary] menarik bayangannya ke 0 dan
/// bergeser sejauh offset bayangan ke kanan-bawah -- efek "ditekan" komik,
/// pengganti splash Material yang sengaja dimatikan secara global (ADR-0006,
/// UX-32). [AppButtonVariant.secondary] dan [AppButtonVariant.tertiary]
/// tidak punya bayangan sejak awal, jadi tidak ada apa pun untuk ditarik.
/// Dipakai [Listener] (bukan [GestureDetector]) supaya hanya mengamati
/// status tekan tanpa ikut merebut gestur dari [ElevatedButton] di
/// dalamnya.
class AppButton extends StatefulWidget {
  /// Membuat [AppButton] varian [AppButtonVariant.primary].
  const AppButton({
    required this.label,
    required this.onPressed,
    this.color,
    this.icon,
    super.key,
  }) : variant = AppButtonVariant.primary,
       textColor = null;

  /// Tombol SEKUNDER (ADR-020 §3.1): isian krem terang dan teks gelap
  /// dengan garis tepi yang sama, TANPA bayangan -- untuk aksi pendamping
  /// (Ubah, Duplikat, Tambah pos, Arsipkan) supaya tidak bersaing dengan
  /// tombol utama, dan untuk aksi destruktif di luar dialog konfirmasi
  /// (beri [textColor] `context.appColors.expense`).
  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.textColor,
    super.key,
  }) : color = null,
       variant = AppButtonVariant.secondary;

  /// Tombol TERSIER (ADR-020 §3.1): tautan teks beraksen tanpa bingkai
  /// maupun bayangan, pola `HomeTextLink` -- untuk aksi paling ringan di
  /// sebuah layar/kartu.
  const AppButton.tertiary({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  }) : color = null,
       textColor = null,
       variant = AppButtonVariant.tertiary;

  /// Teks tombol.
  final String label;

  /// Dipanggil saat tombol ditekan. `null` menonaktifkan tombol.
  final VoidCallback? onPressed;

  /// Warna isian tombol PRIMARY. Bawaan `colorScheme.primary`. Tidak
  /// berlaku untuk [AppButtonVariant.secondary]/[AppButtonVariant.tertiary].
  final Color? color;

  /// Warna teks tombol SECONDARY. Bawaan `colors.textPrimary`. Pakai
  /// `colors.expense` untuk aksi destruktif di luar dialog konfirmasi.
  final Color? textColor;

  /// Ikon opsional di depan [label].
  final IconData? icon;

  /// Tingkat penekanan, lihat [AppButtonVariant].
  final AppButtonVariant variant;

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
    if (widget.variant == AppButtonVariant.tertiary) return _buildTertiary(context);

    final colors = context.appColors;
    final isSecondary = widget.variant == AppButtonVariant.secondary;
    final fill = isSecondary ? colors.surfaceMid : widget.color ?? Theme.of(context).colorScheme.primary;
    final isDisabled = widget.onPressed == null;
    final leadingIcon = widget.icon;
    // Hanya primary punya bayangan untuk ditarik saat ditekan (ADR-020 §3.1
    // -- secondary "TANPA bayangan", jadi tidak ada apa pun untuk dianimasikan).
    final hasElevation = widget.variant == AppButtonVariant.primary;
    final pressed = hasElevation && _pressed && !isDisabled;
    final style = ElevatedButton.styleFrom(
      backgroundColor: isDisabled ? colors.textMuted.withValues(alpha: 0.3) : fill,
      foregroundColor: isSecondary ? widget.textColor ?? colors.textPrimary : null,
      // Bentuk ADR-015: radius pixel 4 dan garis tepi 2px (T-7.5).
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.pixelSmAll,
        side: BorderSide(color: colors.edge, width: AppBorder.pixelThick),
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
          borderRadius: AppRadius.pixelSmAll,
          boxShadow: !hasElevation || isDisabled
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

  Widget _buildTertiary(BuildContext context) {
    final colors = context.appColors;
    final isDisabled = widget.onPressed == null;
    final ink = isDisabled ? colors.textMuted : colors.accent;
    return Semantics(
      button: true,
      enabled: !isDisabled,
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 16, color: ink),
                const SizedBox(width: 4),
              ],
              Text(widget.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ink)),
            ],
          ),
        ),
      ),
    );
  }
}
