import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_setting_row.dart';
import 'package:saldough/core/design_system/ds_theme.dart';

/// Baris setelan bersakelar v2: [DsSettingRow] dengan [Switch] di ujung. Seluruh
/// baris bisa diketuk untuk mengganti nilai dan dibacakan sebagai satu
/// kesatuan (judul, keterangan, status nyala). [onChanged] `null` menonaktifkan.
class DsSwitchRow extends StatelessWidget {
  /// Membuat baris bersakelar.
  const DsSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.badge,
    super.key,
  });

  /// Judul baris.
  final String title;

  /// Keterangan di bawah judul (membungkus).
  final String? subtitle;

  /// Tile ikon di depan, atau `null`.
  final Widget? leading;

  /// Lencana di depan sakelar, mis. `PlusBadge`.
  final Widget? badge;

  /// Nilai sakelar.
  final bool value;

  /// Dipanggil dengan nilai baru.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return MergeSemantics(
      child: DsSettingRow(
        leading: leading,
        title: title,
        subtitle: subtitle,
        onTap: onChanged == null ? null : () => onChanged(!value),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null) ...[badge!, const SizedBox(width: 8)],
            Switch(
              value: value,
              onChanged: onChanged,
              // Centang di kenop saat nyala: status terbaca tanpa bergantung warna.
              thumbIcon: dsSwitchThumbIcon(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ikon kenop sakelar v2: centang saat nyala, kosong saat mati. Dipakai
/// [Switch] di mana pun sakelar dibangun tersendiri.
WidgetStateProperty<Icon?> dsSwitchThumbIcon(BuildContext context) {
  final color = context.ds.colors.actionPrimary;
  return WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.selected) ? Icon(Icons.check_rounded, color: color) : null,
  );
}
