import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/theme/theme.dart';

/// Nada [AppBadge] dan [AppBanner]-nya design system.
enum AppTone {
  /// Netral: jenis, periode ("Bulanan").
  neutral,

  /// Hasil baik: "Aman", "Diterima".
  positive,

  /// Perlu perhatian: "Perlu dicek", "Tertunda", "Hampir habis".
  warning,

  /// Masalah: "Lewat Rp36.000".
  danger,

  /// Keterangan: "Transfer".
  info,

  /// Penanda aplikasi: "Pola bawaan".
  brand,
}

/// Warna latar dan teks per [AppTone].
extension AppToneColors on AppColors {
  /// `(latar, teks)` untuk [tone].
  (Color, Color) toneColors(AppTone tone) => switch (tone) {
    AppTone.neutral => (surface2, ink2),
    AppTone.positive => (positiveSoft, positive),
    AppTone.warning => (warningSoft, warning),
    AppTone.danger => (dangerSoft, danger),
    AppTone.info => (infoSoft, info),
    AppTone.brand => (brandSoft, brandInk),
  };
}

/// Satu sampai tiga kata status di samping isi (komponen Badge, ADR-034).
/// Huruf biasa, tinggi 24px, ikon 16px opsional untuk status yang butuh
/// perhatian. Satu badge per baris atau kartu.
class AppBadge extends StatelessWidget {
  /// Membuat [AppBadge].
  const AppBadge(
    this.label, {
    this.tone = AppTone.neutral,
    this.icon,
    super.key,
  });

  /// Teks badge.
  final String label;

  /// Nada warna.
  final AppTone tone;

  /// Ikon di depan teks.
  final IconKey? icon;

  @override
  Widget build(BuildContext context) {
    final (background, ink) = context.appColors.toneColors(tone);
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: ShapeDecoration(
        color: background,
        shape: const PixelCornerBorder.small(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon(icon!, size: 16, color: ink),
            const SizedBox(width: AppSpacing.space1),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nada [AppBadge] dari warna lama [color] (peralihan Fase 14): warna status
/// jadi nadanya, warna lain netral.
AppTone toneFromColor(AppColors colors, Color? color) {
  if (color == null) return AppTone.neutral;
  if (color == colors.positive) return AppTone.positive;
  if (color == colors.warning || color == colors.warningFill) return AppTone.warning;
  if (color == colors.danger) return AppTone.danger;
  if (color == colors.brand) return AppTone.brand;
  if (color == colors.info) return AppTone.info;
  return AppTone.neutral;
}
