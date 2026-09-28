import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:saldough/core/presentation/motion/motion_policy.dart';

/// Kilau piksel yang berkedip di dalam kotaknya (ADR-021 §3.7). Warnanya
/// bukan hijau/merah/biru — ketiganya milik arah uang (ADR-016).
///
/// Posisi kilau tetap untuk [seed] yang sama. Saat "kurangi gerakan" aktif,
/// kilau tampil diam.
class PixelSparkle extends StatefulWidget {
  /// Membuat [PixelSparkle].
  const PixelSparkle({
    required this.color,
    this.count = 6,
    this.pixel = 3,
    this.seed = 7,
    this.enabled = true,
    super.key,
  });

  /// Warna kilau.
  final Color color;

  /// Jumlah kilau.
  final int count;

  /// Ukuran satu piksel kilau.
  final double pixel;

  /// Benih posisi.
  final int seed;

  /// False menghentikan kedipan.
  final bool enabled;

  @override
  State<PixelSparkle> createState() => _PixelSparkleState();
}

class _PixelSparkleState extends State<PixelSparkle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PixelSparkle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.enabled && !MotionPolicy.reduced(context);
    if (run && !_controller.isAnimating) {
      unawaited(_controller.repeat());
    } else if (!run) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SparklePainter(
            animation: _controller,
            color: widget.color,
            count: widget.count,
            pixel: widget.pixel,
            seed: widget.seed,
            animating: widget.enabled && !MotionPolicy.reduced(context),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({
    required this.animation,
    required this.color,
    required this.count,
    required this.pixel,
    required this.seed,
    required this.animating,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final int count;
  final double pixel;
  final int seed;
  final bool animating;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()..color = color;
    for (var i = 0; i < count; i++) {
      final x = (random.nextDouble() * (size.width - pixel * 3) / pixel).floorToDouble() * pixel;
      final y = (random.nextDouble() * (size.height - pixel * 3) / pixel).floorToDouble() * pixel;
      final phase = random.nextDouble();
      // Tiga frame: titik, silang, padam.
      final frame = animating ? ((animation.value + phase) % 1 * 3).floor() : 1;
      if (frame == 2) continue;
      canvas.drawRect(Rect.fromLTWH(x + pixel, y + pixel, pixel, pixel), paint);
      if (frame == 1) {
        canvas
          ..drawRect(Rect.fromLTWH(x, y + pixel, pixel, pixel), paint)
          ..drawRect(
            Rect.fromLTWH(x + pixel * 2, y + pixel, pixel, pixel),
            paint,
          )
          ..drawRect(Rect.fromLTWH(x + pixel, y, pixel, pixel), paint)
          ..drawRect(
            Rect.fromLTWH(x + pixel, y + pixel * 2, pixel, pixel),
            paint,
          );
      }
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.animating != animating || oldDelegate.count != count;
}
