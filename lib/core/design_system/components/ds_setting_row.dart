import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_pressable.dart';
import 'package:saldough/core/design_system/ds_theme.dart';

/// Baris setelan (acuan Profil): ubin ikon di kiri, judul dan keterangan
/// (membungkus, tidak dipotong), lalu [trailing] (mis. sakelar) atau [badge]
/// (status) dan panah. Dipasang di dalam `DsListCard`.
class DsSettingRow extends StatelessWidget {
  /// Membuat baris setelan.
  const DsSettingRow({
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.badge,
    this.onTap,
    super.key,
  });

  /// Ubin ikon (`DsIconTile`).
  /// Tile atau ikon di depan; `null` untuk baris tanpa ikon (mis. sub-sakelar).
  final Widget? leading;

  /// Judul baris.
  final String title;

  /// Keterangan di bawah judul.
  final String? subtitle;

  /// Pengganti panah, mis. sakelar.
  final Widget? trailing;

  /// Status di sebelah panah; tidak menggantikan panah.
  final Widget? badge;

  /// Dipanggil saat diketuk; `null` untuk baris bersakelar.
  final VoidCallback? onTap;

  /// Status panjang (teks besar, layar sempit) mengecil dan paling lebar 40%
  /// baris, supaya judul tetap punya ruang.
  Widget? _fitted(Widget? badge) {
    if (badge == null) return null;
    return Flexible(
      flex: 0,
      child: LayoutBuilder(
        builder: (context, constraints) => ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.4),
          child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerEnd, child: badge),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final end = trailing ?? _fitted(badge);
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ds.typography.titleMd.copyWith(fontSize: 14)),
                  if (subtitle != null) Text(subtitle!, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            if (end != null) ...[const SizedBox(width: 8), end],
            if (trailing == null && onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: c.textMuted),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return body;
    return DsPressable(onPressed: onTap, pressedScale: 0.995, dimWhenDisabled: false, builder: (context, _) => body);
  }
}
