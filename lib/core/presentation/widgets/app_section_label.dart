import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Label kolom formulir (`tk-field__label`, design system TextField):
/// `label` 14/600 `ink` di kiri, [hint] `body-sm` `ink2` di kanan. `Wrap`
/// supaya [hint] turun baris, bukan meluap, pada teks besar.
///
/// Judul bagian di atas kartu memakai `AppSectionHeader`.
class AppSectionLabel extends StatelessWidget {
  /// Membuat [AppSectionLabel].
  const AppSectionLabel(this.label, {this.hint, super.key});

  /// Label kolom.
  final String label;

  /// Keterangan kecil di ujung kanan.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.space2,
        runSpacing: 2,
        children: [
          Text(label, style: textTheme.labelLarge),
          if (hint != null) Text(hint!, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
        ],
      ),
    );
  }
}
