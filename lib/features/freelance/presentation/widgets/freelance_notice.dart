import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Kartu aturan freelance: judul kecil dan satu paragraf. Dipakai untuk
/// menyatakan bahwa kerja selesai bukan uang diterima, dan bahwa mencatat
/// pembayaran bukan pembayaran yang dijalankan aplikasi (FR-FRL-004).
class FreelanceNotice extends StatelessWidget {
  /// Membuat [FreelanceNotice].
  const FreelanceNotice({required this.title, required this.body, this.color, super.key});

  /// Judul kecil.
  final String title;

  /// Isi.
  final String body;

  /// Warna aksen; bawaan warna tertunda.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Banner nada lembut (design system Banner): latar `*-soft`, ikon dan
    // judul berwarna status, isi `ink`.
    final (background, ink) = colors.toneColors(color == null ? AppTone.warning : toneFromColor(colors, color));
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: ShapeDecoration(color: background, shape: const PixelCornerBorder()),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(IconKey.info, size: 20, color: ink),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.labelLarge?.copyWith(color: ink)),
                const SizedBox(height: 2),
                Text(body, style: textTheme.bodyMedium?.copyWith(color: colors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
