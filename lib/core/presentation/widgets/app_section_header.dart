import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Judul bagian di atas kartu, di atas `bg` (design system bagian Ruang):
/// `title` huruf biasa di kiri, tautan opsional ("Lihat semua", `label`
/// `brand`) atau keterangan kecil di kanan.
class AppSectionHeader extends StatelessWidget {
  /// Membuat [AppSectionHeader].
  const AppSectionHeader(
    this.title, {
    this.hint,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Judul bagian.
  final String title;

  /// Keterangan kecil di kanan (`body-sm` `ink2`), bila tidak ada tautan.
  final String? hint;

  /// Label tautan di kanan.
  final String? actionLabel;

  /// Dipanggil saat tautan diketuk.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.space3,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: textTheme.titleLarge),
            ),
            if (actionLabel != null)
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: AppSpacing.space1,
                    ),
                    child: Text(
                      actionLabel!,
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.brand,
                      ),
                    ),
                  ),
                ),
              )
            else if (hint != null)
              Text(
                hint!,
                style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
              ),
          ],
        ),
      ),
    );
  }
}
