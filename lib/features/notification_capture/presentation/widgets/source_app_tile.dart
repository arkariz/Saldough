import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';

/// Tile aplikasi sumber: **ikon asli** aplikasinya bila ada, kalau tidak huruf
/// pertama namanya. [warn] menandai aplikasi yang perlu diatur (latar merah
/// lembut); [dimmed] untuk yang dijeda.
class SourceAppTile extends StatelessWidget {
  /// Membuat [SourceAppTile].
  const SourceAppTile({
    required this.label,
    this.icon,
    this.warn = false,
    this.dimmed = false,
    this.size = 40,
    super.key,
  });

  /// Nama aplikasi (untuk huruf cadangan).
  final String label;

  /// Ikon PNG aplikasi, atau `null`.
  final Uint8List? icon;

  /// Perlu diatur: latar dan huruf memakai nada galat.
  final bool warn;

  /// Dijeda: tampil pudar.
  final bool dimmed;

  /// Sisi tile.
  final double size;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final radius = BorderRadius.circular(size * 0.28);
    final bytes = icon;
    final Widget face;
    if (bytes != null) {
      face = ClipRRect(
        borderRadius: radius,
        child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true),
      );
    } else {
      final initial = label.trim().isEmpty ? '?' : label.trim().characters.first.toUpperCase();
      face = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: warn ? c.errorContainer.withValues(alpha: 0.5) : c.surfaceSunken,
          borderRadius: radius,
        ),
        child: Text(initial, style: ds.typography.titleMd.copyWith(color: warn ? c.error : c.textPrimary)),
      );
    }
    return ExcludeSemantics(
      child: Opacity(
        opacity: dimmed ? 0.5 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: warn && bytes != null ? Border.all(color: c.error.withValues(alpha: 0.5), width: 1.5) : null,
          ),
          child: face,
        ),
      ),
    );
  }
}
