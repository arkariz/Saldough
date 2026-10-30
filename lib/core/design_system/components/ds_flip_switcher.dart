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
              view = ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 4 * away, sigmaY: 4 * away),
                child: view,
              );
            }
            return Opacity(opacity: animation.value.clamp(0, 1), child: view);
          },
        );
      },
      child: child,
    );
  }
}

/// Mengganti [child] dengan kabur: yang lama mengabur dan memudar, yang baru
/// jernih kembali (280ms). Dipakai saat nominal di kartu saldo hero
/// disembunyikan atau ditampilkan. [child] wajib punya `key` yang berbeda
/// untuk tiap keadaan. Saat gerak dikurangi, pergantian langsung.
class DsBlurSwitcher extends StatelessWidget {
  /// Membuat pengganti kabur.
  const DsBlurSwitcher({required this.child, this.alignment = Alignment.centerLeft, super.key});

  /// Isi saat ini; `key`-nya menentukan kapan dianggap berganti.
  final Widget child;

  /// Perataan isi di dalam pengganti.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final reduced = DsMotion.reduced(context);
    return AnimatedSwitcher(
      duration: reduced ? Duration.zero : const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: [...previous, ?current],
      ),
      transitionBuilder: (incoming, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final away = 1 - animation.value;
          final view = away > 0
              ? ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 6 * away, sigmaY: 6 * away), child: incoming)
              : incoming;
          return Opacity(opacity: (0.4 + 0.6 * animation.value).clamp(0, 1) * animation.value.clamp(0, 1), child: view);
        },
      ),
      child: child,
    );
  }
}
