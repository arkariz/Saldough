import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Panel bergaris tepi tebal dengan bayangan keras offset — dasar seluruh
/// panel komik Saldough. Lihat ADR-0006.
///
/// Dibuat sejak fase fondasi supaya dekorasi panel ini tidak diulang manual
/// di tiap layar (lihat catatan ADR-0006 soal `new-health-duel` yang
/// mengulang dekorasi serupa di sekitar delapan berkas karena tidak pernah
/// dibuat jadi widget bersama).
class AppCard extends StatelessWidget {
  /// Membuat [AppCard] dengan [child] dan padding/sudut opsional.
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius,
    this.elevation = AppElevation.md,
    super.key,
  });

  /// Isi panel.
  final Widget child;

  /// Padding di dalam panel.
  final EdgeInsetsGeometry padding;

  /// Sudut panel. Bawaan [AppRadius.mdAll]; pakai [AppRadius.comicCut] untuk
  /// panel hero/banner.
  final BorderRadius? borderRadius;

  /// Jarak bayangan keras offset, dari [AppElevation].
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = borderRadius ?? AppRadius.mdAll;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: radius,
        border: Border.all(color: colors.edge, width: 2.5),
        boxShadow: elevation > 0 ? AppElevation.hardShadow(colors.edge, offset: elevation) : null,
      ),
      child: child,
    );
  }
}
