import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_card.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/presentation/widgets/transaction_kind.dart';
import 'package:saldough/core/theme/theme.dart';

/// Satu pilihan di [AppMenuSelectButton]: nilai, label, dan ikon.
typedef AppMenuOption<T> = ({T value, String label, IconKey icon});

/// Tombol putih kecil bergaya rujukan ("Dompet ▾") yang membuka menu pilihan
/// bergambar. Dipakai penyaring layar Transaksi dan pemilih kategori/dompet
/// formulir CATAT, supaya seluruh pilihan dropdown di aplikasi tampil dan
/// berperilaku sama.
///
/// [allLabel] mengaktifkan satu item ekstra di puncak menu yang mengirim
/// `null` ke [onSelected] ("Semua dompet" pada penyaring, "Tanpa kategori"
/// pada formulir). `null` -- tanpa item itu.
///
/// Selebar ruang yang diberikan induknya. Secara bawaan label terpotong
/// dengan elipsis kalau panjang; [wrapLabel] membuatnya membungkus ke banyak
/// baris (nama dompet di formulir tidak boleh terpotong). [isPlaceholder]
/// meredupkan label untuk keadaan "belum dipilih".
class AppMenuSelectButton<T> extends StatelessWidget {
  /// Membuat [AppMenuSelectButton].
  const AppMenuSelectButton({
    required this.icon,
    required this.label,
    required this.options,
    required this.onSelected,
    this.allLabel,
    this.allIcon = IconKey.filter,
    this.wrapLabel = false,
    this.isPlaceholder = false,
    this.detailFor,
    this.fieldLabel,
    this.rowIcon,
    this.trailing,
    super.key,
  });

  /// Ikon di kiri tombol.
  final IconKey icon;

  /// Teks tombol: pilihan aktif, atau ajakan memilih.
  final String label;

  /// Pilihan yang ditawarkan, sesuai urutan.
  final List<AppMenuOption<T>> options;

  /// Dipanggil dengan nilai yang dipilih, atau `null` untuk item [allLabel].
  final ValueChanged<T?> onSelected;

  /// Label item "semua"/"kosongkan" di puncak menu; `null` = tanpa item itu.
  final String? allLabel;

  /// Ikon item [allLabel].
  final IconKey allIcon;

  /// Membungkus label panjang alih-alih memotongnya dengan elipsis.
  final bool wrapLabel;

  /// Meredupkan label (keadaan "belum dipilih").
  final bool isPlaceholder;

  /// Mengubah tombol jadi baris form (`tk-row--compact`, design system
  /// ListRow): [fieldLabel] kecil di atas nilai, ikon 24px `ink2`, [trailing]
  /// di kanan, dan chevron. Dipakai baris Dompet dan Anggaran di Catat.
  final String? fieldLabel;

  /// Ikon baris form (Material Symbols); bawaan [icon].
  final IconKey? rowIcon;

  /// Isi kanan baris form, mis. "Saldo jadi Rp331.000".
  final Widget? trailing;

  /// Teks kecil rata kanan di tiap item menu, mis. saldo dompet (UX-11);
  /// `null` = tanpa teks itu.
  final String? Function(T value)? detailFor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final allLabel = this.allLabel;
    return PopupMenuButton<int>(
      // Indeks, bukan nilai: `PopupMenuButton` tidak memanggil `onSelected`
      // untuk nilai `null`, padahal "Semua" justru diwakili `null`.
      onSelected: (index) => onSelected(index < 0 ? null : options[index].value),
      color: colors.surface,
      shape: const PixelCornerBorder(),
      itemBuilder: (_) => [
        if (allLabel != null) _item(value: -1, icon: allIcon, label: allLabel, context: context),
        for (var i = 0; i < options.length; i++)
          _item(
            value: i,
            icon: options[i].icon,
            label: options[i].label,
            detail: detailFor?.call(options[i].value),
            context: context,
          ),
      ],
      child: fieldLabel != null
          ? _row(context)
          : AppCard(
              color: colors.surface2,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: 10,
              ),
              child: Row(
                children: [
                  AppIcon(icon, size: 22),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: wrapLabel ? null : 1,
                      overflow: wrapLabel ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: labelSmStyle(
                        context,
                        color: isPlaceholder ? colors.ink2 : colors.ink,
                      ),
                    ),
                  ),
                  AppIcon(IconKey.dropdown, size: 18, color: colors.ink2),
                ],
              ),
            ),
    );
  }

  Widget _row(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        child: Row(
          children: [
            AppIcon(rowIcon ?? icon, color: colors.ink2),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fieldLabel!,
                    style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                  ),
                  Text(
                    label,
                    maxLines: wrapLabel ? null : 1,
                    overflow: wrapLabel ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: isPlaceholder ? textTheme.bodyLarge?.copyWith(color: colors.ink3) : textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.space2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: trailing,
              ),
            ],
            const SizedBox(width: AppSpacing.space1),
            AppIcon(IconKey.chevronRight, color: colors.ink3),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<int> _item({
    required int value,
    required IconKey icon,
    required String label,
    required BuildContext context,
    String? detail,
  }) {
    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [
          AppIcon(icon),
          const SizedBox(width: AppSpacing.space2),
          // [detail] di bawah label, bukan rata kanan: nominal panjang di
          // layar sempit atau teks diperbesar tidak mendesak labelnya.
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  overflow: wrapLabel ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
                if (detail != null)
                  Text(
                    detail,
                    style: context.numberStyles.amountSm.copyWith(
                      color: context.appColors.ink2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
