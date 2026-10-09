import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Satu baris setelan di layar Akun (prototipe `Akun.dc.html`): ikon 24px
/// `ink2`, judul, keterangan, lalu [trailing] atau panah. Dipasang di dalam
/// `AppListCard(dividerIndent: AppListCard.iconIndent)`.
class SettingRow extends StatelessWidget {
  /// Membuat [SettingRow].
  const SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    super.key,
  });

  /// Ikon baris.
  final IconKey icon;

  /// Judul baris.
  final String title;

  /// Keterangan di bawah judul.
  final String? subtitle;

  /// Pengganti panah, mis. sakelar.
  final Widget? trailing;

  /// Dipanggil saat baris diketuk; `null` untuk baris bersakelar.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppListRow(
    compact: true,
    leading: AppIcon(icon, color: context.appColors.ink2),
    title: title,
    subtitle: subtitle,
    wrapSubtitle: true,
    trailing: trailing,
    chevron: trailing == null,
    onTap: onTap,
  );
}
