import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Kartu banner pembaruan (APP_UPDATE §7, rupa v3): latar `brand` penuh, tile
/// ikon `surface`, judul dengan chip versi (`inverseSurface`; `straw` hanya
/// untuk aksen dekoratif, bukan latar teks) di sebelahnya (membungkus ke
/// bawah bila sempit), tombol × di pojok kanan atas, dan tombol aksi di
/// bawahnya. Tanpa [onDismiss] / [actionLabel] bagian itu tidak ada.
class UpdateBannerCard extends StatelessWidget {
  /// Membuat [UpdateBannerCard].
  const UpdateBannerCard({
    required this.title,
    required this.icon,
    this.spin = false,
    this.versionChip,
    this.actionLabel,
    this.onAction,
    this.dismissLabel,
    this.onDismiss,
    super.key,
  });

  /// Judul satu kalimat.
  final String title;

  /// Ikon di tile.
  final IconKey icon;

  /// Ikon berputar ("mengunduh").
  final bool spin;

  /// Nama versi di chip ("v0.7.0"); `null` = tanpa chip.
  final String? versionChip;

  /// Label tombol aksi; `null` = tanpa tombol.
  final String? actionLabel;

  /// Dipanggil saat tombol aksi diketuk.
  final VoidCallback? onAction;

  /// Label aksesibilitas ×; `null` = tanpa ×.
  final String? dismissLabel;

  /// Dipanggil saat × diketuk.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final glyph = AppIcon(icon, color: colors.brand);
    final hasRight = actionLabel != null || dismissLabel != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space3, AppSpacing.space2, AppSpacing.space3),
      decoration: ShapeDecoration(color: colors.brand, shape: const PixelCornerBorder()),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: ShapeDecoration(color: colors.surface, shape: const PixelCornerBorder.small()),
            child: spin ? AppSpin(child: glyph) : glyph,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
              child: Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space1,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(title, style: textTheme.titleMedium?.copyWith(color: colors.onBrand)),
                  if (versionChip case final chip?)
                    Container(
                      key: const ValueKey('app-update-version-chip'),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2, vertical: 2),
                      decoration: ShapeDecoration(color: colors.inverseSurface, shape: const PixelCornerBorder.small()),
                      child: Text(chip, style: textTheme.labelMedium?.copyWith(color: colors.onInverse)),
                    ),
                ],
              ),
            ),
          ),
          if (hasRight) ...[
            const SizedBox(width: AppSpacing.space2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (dismissLabel case final label?)
                  Semantics(
                    button: true,
                    label: label,
                    excludeSemantics: true,
                    onTap: onDismiss,
                    child: GestureDetector(
                      key: const ValueKey('app-update-dismiss'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onDismiss,
                      child: SizedBox(
                        width: AppSize.touch,
                        height: 40,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.space1, right: AppSpacing.space2),
                            child: AppIcon(IconKey.close, size: 20, color: colors.onBrand),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (actionLabel case final label?)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.space2),
                    child: Semantics(
                      button: true,
                      child: GestureDetector(
                        key: const ValueKey('app-update-action'),
                        behavior: HitTestBehavior.opaque,
                        onTap: onAction,
                        child: Container(
                          height: AppSize.buttonSm,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: ShapeDecoration(color: colors.surface, shape: const PixelCornerBorder.small()),
                          child: Text(label, style: textTheme.labelLarge?.copyWith(color: colors.brandInk)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
