import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/theme/theme.dart';

/// Baris daftar (komponen ListRow, ADR-034): transaksi, dompet, pos
/// anggaran, baris form, dan setelan.
///
/// Anatomi: [leading] (tile ikon 40px atau ikon 24px) → [title] (`body-strong`,
/// satu baris dengan elipsis) dan [subtitle] (`body-sm` `ink2`) → [trailing]
/// (nominal, badge, atau switch). [label] di atas judul untuk baris form.
/// Tinggi minimal 64px (56px dengan [compact]). Seluruh baris satu target
/// sentuh; tekan: `surface2`. [chevron] menambah panah di akhir.
class AppListRow extends StatelessWidget {
  /// Membuat [AppListRow].
  const AppListRow({
    required this.title,
    this.subtitle,
    this.label,
    this.leading,
    this.trailing,
    this.onTap,
    this.chevron = false,
    this.compact = false,
    this.semanticsLabel,
    this.wrapTitle = false,
    super.key,
  });

  /// Judul baris.
  final String title;

  /// Subjudul ("BCA · 12.00").
  final String? subtitle;

  /// Label kecil di atas judul (baris form: "Dompet").
  final String? label;

  /// Tile ikon atau ikon di awal.
  final Widget? leading;

  /// Isi akhir: nominal, badge, switch.
  final Widget? trailing;

  /// Dipanggil saat baris diketuk.
  final VoidCallback? onTap;

  /// Panah di akhir baris.
  final bool chevron;

  /// Varian rapat (56px).
  final bool compact;

  /// Label pembaca layar pengganti gabungan teks baris.
  final String? semanticsLabel;

  /// Judul membungkus ke banyak baris alih-alih elipsis (nama dompet tidak
  /// boleh terpotong, UX-20).
  final bool wrapTitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final row = LayoutBuilder(
      builder: (context, constraints) => _row(context, constraints.maxWidth / 2),
    );
    if (onTap == null) return Semantics(label: semanticsLabel, child: row);
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        onTap: onTap,
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed) ? colors.surface2 : Colors.transparent,
        ),
        child: row,
      ),
    );
  }

  Widget _row(BuildContext context, double maxTrailing) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: compact ? 56 : AppSize.row),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: compact ? AppSpacing.space2 : AppSpacing.space3,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.space3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null)
                    Text(
                      label!,
                      style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                    ),
                  Text(
                    title,
                    maxLines: wrapTitle ? null : 1,
                    overflow: wrapTitle ? null : TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.ink2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.space3),
              // Nominal rata kanan dan tidak pernah terpotong: paling lebar
              // separuh baris, diperkecil bila tetap tidak muat (layar
              // sempit, teks 200%).
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxTrailing),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: trailing,
                ),
              ),
            ],
            if (chevron) ...[
              const SizedBox(width: AppSpacing.space1),
              AppIcon(IconKey.chevronRight, color: colors.ink3),
            ],
          ],
        ),
      ),
    );
  }
}
