import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/theme/theme.dart';

/// Varian [AppButton] (komponen Button design system, ADR-034).
enum AppButtonVariant {
  /// Isian `brand`: tindakan yang menjadi tujuan layar. Paling banyak satu
  /// per layar.
  primary,

  /// Isian `surface2`: tindakan pendamping.
  secondary,

  /// Teks `brand` tanpa isian: tindakan ringan atau navigasi ("Lihat
  /// semua", "Batal").
  text,

  /// Teks `danger` tanpa isian: tindakan permanen ("Hapus dompet").
  danger,
}

/// Tombol design system: satu tindakan yang jelas, teks kata kerja + benda.
///
/// Tinggi `size-button` (48), atau `size-button-sm` (36) dengan [small] —
/// area sentuhnya tetap 48. [expand] melebarkan tombol penuh (tombol yang
/// menempel di bawah layar). [loading] mengganti teks dengan pemutar dan
/// mengunci tombol. `onPressed` `null` menonaktifkan tombol
/// (`opacity-disabled`); sertakan alasannya di dekat tombol.
///
/// Sudut piksel kecil (`pixel-step-sm`), tanpa bingkai dan bayangan. Ikon
/// hanya bila menambah makna (+ untuk tambah).
class AppButton extends StatefulWidget {
  /// Tombol utama ([AppButtonVariant.primary]).
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.small = false,
    this.expand = false,
    this.loading = false,
    super.key,
  }) : variant = AppButtonVariant.primary;

  /// Tombol pendamping ([AppButtonVariant.secondary]).
  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.small = false,
    this.expand = false,
    this.loading = false,
    super.key,
  }) : variant = AppButtonVariant.secondary;

  /// Tombol teks ([AppButtonVariant.text]).
  const AppButton.text({
    required this.label,
    required this.onPressed,
    this.icon,
    this.small = false,
    this.expand = false,
    this.loading = false,
    super.key,
  }) : variant = AppButtonVariant.text;

  /// Tombol tindakan permanen ([AppButtonVariant.danger]).
  const AppButton.danger({
    required this.label,
    required this.onPressed,
    this.icon,
    this.small = false,
    this.expand = false,
    this.loading = false,
    super.key,
  }) : variant = AppButtonVariant.danger;

  /// Teks tombol.
  final String label;

  /// Dipanggil saat tombol ditekan. `null` menonaktifkan tombol.
  final VoidCallback? onPressed;

  /// Ikon opsional di depan [label].
  final IconKey? icon;

  /// Ukuran kecil (36px), untuk tombol di dalam kartu dan banner.
  final bool small;

  /// Lebar penuh.
  final bool expand;

  /// Sedang menyimpan: pemutar menggantikan teks dan tombol terkunci.
  final bool loading;

  /// Varian, lihat [AppButtonVariant].
  final AppButtonVariant variant;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final (Color fill, Color pressedFill, Color ink) = switch (widget.variant) {
      AppButtonVariant.primary => (colors.brand, colors.brandPressed, colors.onBrand),
      AppButtonVariant.secondary => (colors.surface2, colors.surface3, colors.ink),
      AppButtonVariant.text => (Colors.transparent, colors.surface2, colors.brand),
      AppButtonVariant.danger => (Colors.transparent, colors.dangerSoft, colors.danger),
    };
    final filled = widget.variant == AppButtonVariant.primary || widget.variant == AppButtonVariant.secondary;
    final height = widget.small ? AppSize.buttonSm : AppSize.button;
    final horizontal = !filled ? AppSpacing.space3 : (widget.small ? 14.0 : AppSpacing.space5);
    final labelStyle = (widget.small ? textTheme.labelLarge : textTheme.titleMedium)?.copyWith(color: ink);

    final Widget content = widget.loading
        ? SizedBox.square(
            dimension: AppSize.iconSm,
            child: CircularProgressIndicator(strokeWidth: 2, color: ink),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                AppIcon(widget.icon!, size: AppSize.iconSm, color: ink),
                const SizedBox(width: AppSpacing.space2),
              ],
              Flexible(
                child: Text(widget.label, style: labelStyle, textAlign: TextAlign.center),
              ),
            ],
          );

    final button = AnimatedContainer(
      duration: AppDurations.fast,
      constraints: BoxConstraints(minHeight: height, minWidth: widget.expand ? double.infinity : height),
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      decoration: ShapeDecoration(
        color: _pressed ? pressedFill : fill,
        shape: const PixelCornerBorder.small(),
      ),
      // `Center` berfaktor 1, bukan `alignment`: `alignment` membuat tombol
      // memenuhi tinggi yang ditawarkan (mis. setinggi layar di
      // `bottomNavigationBar`).
      child: Center(widthFactor: 1, heightFactor: 1, child: content),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.loading ? widget.label : null,
      child: Opacity(
        opacity: widget.onPressed == null ? AppSize.disabledOpacity : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _enabled ? widget.onPressed : null,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: ConstrainedBox(
            // Area sentuh 48 walau tombol kecil 36 (design system Button).
            constraints: BoxConstraints(minHeight: AppSize.touch, minWidth: widget.expand ? double.infinity : 0),
            child: Align(widthFactor: widget.expand ? null : 1, heightFactor: 1, child: button),
          ),
        ),
      ),
    );
  }
}

/// Tombol ikon saja (`iconbtn`, 48px) dengan label aksesibilitas wajib.
class AppIconButton extends StatelessWidget {
  /// Membuat [AppIconButton].
  const AppIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tonal = false,
    this.color,
    super.key,
  });

  /// Ikon tombol.
  final IconKey icon;

  /// Label pembaca layar dan tooltip ("Cari", "Kembali").
  final String label;

  /// Dipanggil saat ditekan; `null` menonaktifkan.
  final VoidCallback? onPressed;

  /// Latar `surface2` (varian `--tonal`).
  final bool tonal;

  /// Warna ikon. Bawaan `ink`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: label,
        excludeSemantics: true,
        child: Opacity(
          opacity: onPressed == null ? AppSize.disabledOpacity : 1,
          child: Material(
            type: tonal ? MaterialType.canvas : MaterialType.transparency,
            color: tonal ? colors.surface2 : null,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              overlayColor: WidgetStatePropertyAll(colors.surface2),
              child: SizedBox.square(
                dimension: AppSize.touch,
                child: Center(child: AppIcon(icon, color: color ?? colors.ink)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
