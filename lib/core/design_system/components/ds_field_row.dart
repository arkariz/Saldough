import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_pressable.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Kelompok baris isian dalam satu kartu putih bergaris rambut, dipisah garis
/// tipis (acuan Catat v2: dompet, catatan, waktu). Sudut 16.
class DsFieldGroup extends StatelessWidget {
  /// Membuat kelompok.
  const DsFieldGroup({required this.children, super.key});

  /// Baris, biasanya [DsFieldRow].
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: DsRadius.lgAll,
        border: Border.all(color: c.outlineSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) Divider(height: 1, thickness: 1, indent: 44, color: c.outlineSubtle),
            child,
          ],
        ],
      ),
    );
  }
}

/// Satu baris isian: ikon aksen, label kapital kecil, lalu nilai (atau
/// [child] bebas, mis. kolom teks), dengan [trailing] atau tanda panah di
/// kanan. Seluruh baris bisa diketuk bila [onTap] diisi.
class DsFieldRow extends StatelessWidget {
  /// Membuat baris.
  const DsFieldRow({
    required this.icon,
    required this.label,
    this.title,
    this.child,
    this.leading,
    this.trailing,
    this.chevron = false,
    this.placeholder = false,
    this.onTap,
    this.semanticsLabel,
    super.key,
  }) : assert(title != null || child != null, 'butuh title atau child');

  /// Ikon aksen di kiri; diabaikan bila [leading] diisi.
  final IconData icon;

  /// Widget pengganti ikon (mis. ikon clay dompet).
  final Widget? leading;

  /// Label kecil.
  final String label;

  /// Nilai satu baris atau lebih.
  final String? title;

  /// Isi bebas pengganti [title].
  final Widget? child;

  /// Isi kanan, mis. saldo setelahnya.
  final Widget? trailing;

  /// Tanda panah kanan.
  final bool chevron;

  /// Nilai berupa petunjuk (belum dipilih): lebih redup.
  final bool placeholder;

  /// Dipanggil saat baris diketuk.
  final VoidCallback? onTap;

  /// Label pembaca layar pengganti "label, nilai".
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: leading ?? Icon(icon, size: 20, color: c.actionPrimary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: ds.typography.pixelCaption.copyWith(color: c.textMuted, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  child ??
                      Text(
                        title!,
                        style: ds.typography.bodyMd.copyWith(
                          fontSize: 14,
                          fontWeight: placeholder ? FontWeight.w400 : FontWeight.w600,
                          fontVariations: [FontVariation.weight(placeholder ? 400 : 600)],
                          color: placeholder ? c.textMuted : c.textPrimary,
                        ),
                      ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 140), child: trailing),
            ],
            if (chevron) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: c.textMuted),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return body;
    return DsPressable(
      onPressed: onTap,
      pressedScale: 0.995,
      dimWhenDisabled: false,
      semanticLabel: semanticsLabel,
      builder: (context, _) => body,
    );
  }
}

/// Satu pilihan [DsSelectRow].
@immutable
class DsMenuOption<T> {
  /// Membuat pilihan.
  const DsMenuOption({required this.value, required this.label, this.leading, this.detail});

  /// Nilai pilihan.
  final T value;

  /// Teks pilihan.
  final String label;

  /// Ikon di depan teks (mis. ikon clay), 24px.
  final Widget? leading;

  /// Keterangan di bawah teks (mis. saldo dompet).
  final String? detail;
}

/// Baris isian bermenu pilihan: [DsFieldRow] yang membuka menu popup (tema
/// popup v2). [allLabel] menambah pilihan pertama yang mengirim `null`
/// ("Tanpa anggaran").
class DsSelectRow<T> extends StatelessWidget {
  /// Membuat baris pilihan.
  const DsSelectRow({
    required this.icon,
    required this.label,
    required this.title,
    required this.options,
    required this.onSelected,
    this.leading,
    this.trailing,
    this.placeholder = false,
    this.allLabel,
    super.key,
  });

  /// Ikon aksen baris.
  final IconData icon;

  /// Widget pengganti ikon.
  final Widget? leading;

  /// Label kecil baris.
  final String label;

  /// Nilai terpilih, atau petunjuk bila [placeholder].
  final String title;

  /// Isi kanan.
  final Widget? trailing;

  /// Belum dipilih.
  final bool placeholder;

  /// Pilihan.
  final List<DsMenuOption<T>> options;

  /// Teks pilihan "tidak ada" yang mengirim `null`.
  final String? allLabel;

  /// Dipanggil dengan nilai terpilih, atau `null` untuk [allLabel].
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    Widget item(String text, {Widget? lead, String? detail}) => Row(
      children: [
        if (lead != null) ...[SizedBox(width: 24, height: 24, child: lead), const SizedBox(width: 10)],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, overflow: TextOverflow.ellipsis),
              if (detail != null)
                Text(detail, style: ds.typography.amountSm.copyWith(fontSize: 12, color: c.textSecondary)),
            ],
          ),
        ),
      ],
    );
    return PopupMenuButton<int>(
      // Indeks, bukan nilai: `PopupMenuButton` tidak memanggil `onSelected`
      // untuk `null`, padahal "tidak ada" diwakili `null`.
      onSelected: (index) => onSelected(index < 0 ? null : options[index].value),
      itemBuilder: (_) => [
        if (allLabel != null) PopupMenuItem<int>(value: -1, child: item(allLabel!)),
        for (var i = 0; i < options.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: item(options[i].label, lead: options[i].leading, detail: options[i].detail),
          ),
      ],
      child: DsFieldRow(
        icon: icon,
        leading: leading,
        label: label,
        title: title,
        placeholder: placeholder,
        trailing: trailing,
        chevron: true,
      ),
    );
  }
}
