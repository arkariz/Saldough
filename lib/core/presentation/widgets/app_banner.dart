import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_badge.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/theme/theme.dart';

/// Pesan satu kalimat yang meminta perhatian, dengan satu tindakan
/// (komponen Banner, ADR-034). Paling banyak satu per layar, di bawah angka
/// utama. Latar `*Soft` sesuai [tone], ikon berwarna nada, teks `ink`,
/// tindakan tombol kecil `surface`.
class AppBanner extends StatelessWidget {
  /// Membuat [AppBanner].
  const AppBanner({
    required this.message,
    this.tone = AppTone.warning,
    this.icon = IconKey.info,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    super.key,
  });

  /// Satu kalimat pesan.
  final String message;

  /// Nada: warning, info, danger, atau positive.
  final AppTone tone;

  /// Ikon di depan pesan.
  final IconKey icon;

  /// Label tindakan ("Cek").
  final String? actionLabel;

  /// Dipanggil saat tindakan diketuk.
  final VoidCallback? onAction;

  /// Tindakan kedua berupa teks tanpa latar ("Nanti"), di kiri [actionLabel];
  /// dipakai banner yang bisa ditunda.
  final String? secondaryActionLabel;

  /// Dipanggil saat tindakan kedua diketuk.
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (background, ink) = colors.toneColors(tone);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        10,
        AppSpacing.space2,
        10,
      ),
      decoration: ShapeDecoration(
        color: background,
        shape: const PixelCornerBorder(),
      ),
      child: Row(
        children: [
          AppIcon(icon, color: ink),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: colors.ink),
            ),
          ),
          if (secondaryActionLabel case final label?) ...[
            const SizedBox(width: AppSpacing.space2),
            _BannerAction(label: label, onTap: onSecondaryAction, filled: false),
          ],
          if (actionLabel case final label?) ...[
            const SizedBox(width: AppSpacing.space2),
            _BannerAction(label: label, onTap: onAction, filled: true),
          ],
        ],
      ),
    );
  }
}

/// Tombol kecil di banner: berlatar `surface` bila [filled], teks saja bila
/// tidak. Area ketuk 48dp.
class _BannerAction extends StatelessWidget {
  const _BannerAction({required this.label, required this.onTap, required this.filled});

  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.ink);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.touch),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Container(
              height: AppSize.buttonSm,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: filled ? ShapeDecoration(color: colors.surface, shape: const PixelCornerBorder.small()) : null,
              child: Text(label, style: labelStyle),
            ),
          ),
        ),
      ),
    );
  }
}
