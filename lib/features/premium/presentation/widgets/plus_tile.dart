import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

/// Ubin ikon Plus: ikon clay di atas latar `actionPrimary` tipis, sudut
/// membulat. Ikon yang belum punya clay jatuh ke simbol Material. Dipakai
/// paywall, daftar fitur, layar berhasil, dan kartu Plus; ikonnya dekoratif.
class PlusTile extends StatelessWidget {
  /// Membuat [PlusTile].
  const PlusTile(this.icon, {this.size = 48, super.key});

  /// Ikon di dalam tile.
  final IconKey icon;

  /// Sisi tile.
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final clay = ClayIcons.forIcon(icon);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.actionPrimary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: clay != null
            ? SvgPicture.asset(clay, width: size * 0.64, height: size * 0.64)
            : AppIcon(icon, size: size * 0.5, color: c.actionPrimary),
      ),
    );
  }
}
