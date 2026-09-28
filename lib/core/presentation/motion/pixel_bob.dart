import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:saldough/core/presentation/motion/motion_policy.dart';

/// Naik-turun [amplitude] piksel dalam dua "frame", seperti sprite diam yang
/// bernapas (ADR-021 §3.7).
///
/// Berhenti saat [enabled] false, saat "kurangi gerakan" aktif, dan saat
/// `TickerMode` subtree-nya mati (mis. halaman `PageView` yang tidak tampil).
class PixelBob extends StatefulWidget {
  /// Membuat [PixelBob] untuk [child].
  const PixelBob({
    required this.child,
    this.amplitude = 2,
    this.period = const Duration(milliseconds: 1200),
    this.phase = 0,
    this.enabled = true,
    super.key,
  });

  /// Widget yang bergerak.
  final Widget child;

  /// Jarak naik, dalam piksel logis.
  final double amplitude;

  /// Lama satu siklus naik-turun.
  final Duration period;

  /// Pergeseran fase 0..1, supaya beberapa elemen tidak bergerak serempak.
  final double phase;

  /// False menghentikan gerak di posisi dasar.
  final bool enabled;

  @override
  State<PixelBob> createState() => _PixelBobState();
}

class _PixelBobState extends State<PixelBob> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PixelBob oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.enabled && !MotionPolicy.reduced(context);
    if (run && !_controller.isAnimating) {
      unawaited(_controller.repeat());
    } else if (!run && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = (_controller.value + widget.phase) % 1;
        // Dua frame: dasar, lalu naik — bukan sinus mulus.
        final dy = _controller.isAnimating && t >= 0.5 ? -widget.amplitude : 0.0;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
    );
  }
}
