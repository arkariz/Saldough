import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';

/// Ubin ikon baris setelan: ikon clay bila [icon] sudah digambar, simbol
/// Material di tile datar bila belum (KT-DS5).
class SettingIconTile extends StatelessWidget {
  /// Membuat [SettingIconTile].
  const SettingIconTile(this.icon, {super.key});

  /// Kunci ikon.
  final IconKey icon;

  @override
  Widget build(BuildContext context) {
    final clay = ClayIcons.forIcon(icon);
    if (clay != null) return DsIconTile.asset(asset: clay);
    return DsIconTile.child(
      size: DsIconTileSize.md,
      child: AppIcon(icon, size: 20, color: context.ds.colors.actionPrimary),
    );
  }
}
