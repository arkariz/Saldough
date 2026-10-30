import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_celebration.dart';
import 'package:saldough/core/design_system/components/ds_pressable.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';
import 'package:saldough/core/design_system/tokens/ds_spacing.dart';

/// Varian [DsButton] (`components.md` bagian Tombol).
enum DsButtonVariant {
  /// Isi `actionPrimary`: tindakan utama layar.
  primary,

  /// Putih bergaris rambut: tindakan pendamping.
  secondary,

  /// Tanpa isi dan bingkai: tindakan ringan.
  ghost,

  /// Putih di atas kartu saldo hero.
  onHero,

  /// Hijau tonal di atas kartu saldo hero.
  onHeroTonal,

  /// Kecil berhuruf piksel kapital, di dalam banner dan baris.
  compact,
}

/// Tombol design system baru: satu tindakan, teks kata kerja + benda.
///
/// Area sentuh minimal 44px walau tombol [DsButtonVariant.compact] lebih
/// pendek. [expand] melebarkan tombol penuh. `onPressed` `null`
/// menonaktifkan tombol.
class DsButton extends StatelessWidget {
  /// Tombol utama.
  const DsButton({required this.label, required this.onPressed, this.icon, this.expand = false, super.key})
    : variant = DsButtonVariant.primary;

  /// Tombol sekunder.
  const DsButton.secondary({required this.label, required this.onPressed, this.icon, this.expand = false, super.key})
    : variant = DsButtonVariant.secondary;

  /// Tombol hantu.
  const DsButton.ghost({required this.label, required this.onPressed, this.icon, this.expand = false, super.key})
    : variant = DsButtonVariant.ghost;

  /// Tombol putih di kartu saldo hero.
  const DsButton.onHero({required this.label, required this.onPressed, this.icon, this.expand = true, super.key})
    : variant = DsButtonVariant.onHero;

  /// Tombol tonal di kartu saldo hero.
  const DsButton.onHeroTonal({required this.label, required this.onPressed, this.icon, this.expand = true, super.key})
    : variant = DsButtonVariant.onHeroTonal;

  /// Tombol ringkas ("KLAIM"). [label] ditulis kapital oleh pemanggil.
  const DsButton.compact({required this.label, required this.onPressed, super.key})
    : variant = DsButtonVariant.compact,
      icon = null,
      expand = false;

  /// Teks tombol.
  final String label;

  /// Dipanggil saat ditekan; `null` menonaktifkan.
  final VoidCallback? onPressed;

  /// Ikon opsional di depan [label] (17px).
  final IconData? icon;

  /// Lebar penuh.
  final bool expand;

  /// Varian.
  final DsButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final hairline = c.onHero.withValues(alpha: 0.1);
    final (Color fill, Color pressedFill, Color ink, Color? border, Color? pressedBorder) = switch (variant) {
      DsButtonVariant.primary => (c.actionPrimary, c.actionPrimaryPressed, c.onActionPrimary, null, null),
      DsButtonVariant.secondary => (
        c.actionSecondary,
        c.actionSecondaryPressed,
        c.onActionSecondary,
        c.outlineSubtle,
        c.outlineStrong,
      ),
      DsButtonVariant.ghost => (Colors.transparent, c.actionGhostPressed, c.actionGhost, null, null),
      DsButtonVariant.onHero => (c.onHero, c.onHero, c.primaryContainer, null, null),
      DsButtonVariant.onHeroTonal => (c.heroActionSecondary, c.heroActionSecondary, c.onHero, hairline, hairline),
      DsButtonVariant.compact => (c.actionPrimary, c.actionPrimaryPressed, c.onActionPrimary, null, null),
    };
    final compact = variant == DsButtonVariant.compact;
    final onHero = variant == DsButtonVariant.onHero || variant == DsButtonVariant.onHeroTonal;
    final radius = onHero ? DsRadius.mdAll : DsRadius.baseAll;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: DsSpacing.xs)
        : EdgeInsets.symmetric(horizontal: onHero ? 12 : 20, vertical: 10);
    final style = (compact ? ds.typography.pixelCaption : ds.typography.button).copyWith(color: ink);

    return DsPressable(
      onPressed: onPressed,
      builder: (context, pressed) => ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: DsSpacing.minTapTarget,
          minWidth: expand ? double.infinity : DsSpacing.minTapTarget,
        ),
        child: Center(
          widthFactor: expand ? null : 1,
          heightFactor: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: expand ? double.infinity : null,
            padding: padding,
            decoration: BoxDecoration(
              color: pressed ? pressedFill : fill,
              borderRadius: radius,
              border: border == null ? null : Border.all(color: pressed ? pressedBorder! : border),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: ink),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(label, style: style, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol ikon saja dengan label aksesibilitas wajib (lonceng, mata).
class DsIconButton extends StatelessWidget {
  /// Tombol ikon bulat 36px di permukaan terang.
  const DsIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.bounceTrigger,
    super.key,
  }) : onHero = false;

  /// Tombol ikon di atas kartu saldo hero: bulat 32px, latar hitam 25%,
  /// garis putih 20%.
  const DsIconButton.onHero({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.bounceTrigger,
    super.key,
  }) : onHero = true;

  /// Ikon.
  final IconData icon;

  /// Label pembaca layar dan tooltip.
  final String label;

  /// Dipanggil saat ditekan; `null` menonaktifkan.
  final VoidCallback? onPressed;

  /// Varian di atas kartu saldo hero.
  final bool onHero;

  /// Bila diisi, ikon memantul tiap nilainya berubah (mis. saat mata
  /// berganti terbuka/tertutup).
  final int? bounceTrigger;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final glyph = Icon(icon, size: onHero ? 18 : 20, color: onHero ? c.onHero : c.textSecondary);
    final trigger = bounceTrigger;
    return Tooltip(
      message: label,
      child: DsPressable(
        onPressed: onPressed,
        semanticLabel: label,
        pressedScale: onHero ? 0.9 : 1,
        builder: (context, pressed) => SizedBox.square(
          dimension: DsSpacing.minTapTarget,
          child: Center(
            child: AnimatedContainer(
              duration: DsMotion.standard,
              width: onHero ? 32 : 36,
              height: onHero ? 32 : 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: onHero
                    ? Colors.black.withValues(alpha: pressed ? 0.4 : 0.25)
                    : (pressed ? c.surfaceContainer : null),
                shape: BoxShape.circle,
                border: onHero ? Border.all(color: c.onHero.withValues(alpha: 0.2)) : null,
              ),
              child: trigger == null ? glyph : DsBounce(trigger: trigger, child: glyph),
            ),
          ),
        ),
      ),
    );
  }
}
