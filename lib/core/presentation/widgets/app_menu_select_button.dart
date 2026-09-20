import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/kind_surfaces.dart';
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final allLabel = this.allLabel;
    return PopupMenuButton<int>(
      // Indeks, bukan nilai: `PopupMenuButton` tidak memanggil `onSelected`
      // untuk nilai `null`, padahal "Semua" justru diwakili `null`.
      onSelected: (index) => onSelected(index < 0 ? null : options[index].value),
      color: colors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: colors.edge, width: AppBorder.pixelThick),
      ),
      itemBuilder: (_) => [
        if (allLabel != null) _item(value: -1, icon: allIcon, label: allLabel),
        for (var i = 0; i < options.length; i++) _item(value: i, icon: options[i].icon, label: options[i].label),
      ],
      child: TransactionSlab(
        radius: 4,
        shadow: 2,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
        child: Row(
          children: [
            AppIcon(icon, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: wrapLabel ? null : 1,
                overflow: wrapLabel ? TextOverflow.visible : TextOverflow.ellipsis,
                style: transactionLabelStyle(context, color: isPlaceholder ? colors.textMuted : colors.textPrimary),
              ),
            ),
            AppIcon(IconKey.dropdown, size: 18, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<int> _item({required int value, required IconKey icon, required String label}) {
    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [
          AppIcon(icon),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(label, overflow: wrapLabel ? TextOverflow.visible : TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
