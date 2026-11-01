import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

/// Satu baris setelan di layar Akun (acuan Profil): ubin ikon clay, judul,
/// keterangan, lalu [trailing] atau panah. Dipasang di dalam `DsListCard`.
class SettingRow extends StatelessWidget {
  /// Membuat [SettingRow].
  const SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.badge,
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

  /// Status di sebelah panah (mis. Nyala/Mati); tidak menggantikan panah.
  final Widget? badge;

  /// Dipanggil saat baris diketuk; `null` untuk baris bersakelar.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DsSettingRow(
    leading: SettingIconTile(icon),
    title: title,
    subtitle: subtitle,
    trailing: trailing,
    badge: badge,
    onTap: onTap,
  );
}
