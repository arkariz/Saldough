import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_list_row.dart';

/// Baris bersakelar (design system ListRow + Switch): judul, keterangan,
/// sakelar di ujung. Seluruh baris bisa diketuk untuk mengganti nilai, dan
/// dibacakan sebagai satu kesatuan. [onChanged] `null` menonaktifkan.
class AppSwitchRow extends StatelessWidget {
  /// Membuat [AppSwitchRow].
  const AppSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    super.key,
  });

  /// Judul baris.
  final String title;

  /// Keterangan di bawah judul.
  final String? subtitle;

  /// Ikon atau tile di depan.
  final Widget? leading;

  /// Nilai sakelar.
  final bool value;

  /// Dipanggil dengan nilai baru.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return MergeSemantics(
      child: AppListRow(
        compact: true,
        wrapTitle: true,
        wrapSubtitle: true,
        leading: leading,
        title: title,
        subtitle: subtitle,
        onTap: onChanged == null ? null : () => onChanged(!value),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}
