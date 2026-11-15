import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';

/// Muncul berurutan: memudar dan naik 10 dp, tertunda [index] x [step]
/// (rupa D6, baris dan ubin rapor). Langsung tampil bila gerak dikurangi.
class StaggerIn extends StatelessWidget {
  /// Membuat [StaggerIn].
  const StaggerIn({required this.index, required this.child, this.step = const Duration(milliseconds: 70), super.key});

  /// Urutan; 0 muncul pertama.
  final int index;

  /// Isi.
  final Widget child;

  /// Selang antar urutan.
  final Duration step;

  @override
  Widget build(BuildContext context) {
    if (DsMotion.reduced(context)) return child;
    final delay = step * index;
    const total = Duration(milliseconds: 420);
    final all = total + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: all,
      curve: Interval(delay.inMilliseconds / all.inMilliseconds, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
