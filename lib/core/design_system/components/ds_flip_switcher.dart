import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';

/// Mengganti [child] dengan balik 3D + kabur: yang lama berputar keluar
/// (200ms), yang baru berputar masuk (250ms). Dipakai saat nominal
/// disembunyikan atau ditampilkan.
///
/// [child] wajib punya `key` yang berbeda untuk tiap keadaan. Saat gerak
/// dikurangi, pergantian langsung.
class DsFlipSwitcher extends StatelessWidget {
  /// Membuat pengganti balik.
  const DsFlipSwitcher({required this.child, super.key});

  /// Isi saat ini; `key`-nya menentukan kapan dianggap berganti.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = DsMotion.reduced(context);
    return AnimatedSwitcher(
      duration: reduced ? Duration.zero : DsMotion.flipIn,
      reverseDuration: reduced ? Duration.zero : DsMotion.flipOut,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeInOut,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, ?current],
      ),
      transitionBuilder: (incoming, animation) {
        final isIncoming = incoming.key == child.key;
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final away = 1 - animation.value;
            final angle = (isIncoming ? -1 : 1) * 70 * math.pi / 180 * away;
            Widget view = Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 1 / 400)
                ..rotateX(angle),
              child: incoming,
            );
            if (away > 0) {
              view = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 4 * away, sigmaY: 4 * away), child: view);
            }
            return Opacity(opacity: animation.value.clamp(0, 1), child: view);
          },
        );
      },
      child: child,
    );
  }
}
