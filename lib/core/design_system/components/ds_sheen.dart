import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';

/// Kilat putih diagonal yang menyapu [child] tiap [period] (rupa D5, tombol
/// Buka rapor). Tidak menangkap sentuhan dan tidak mengubah ukuran. Diam saat
/// gerak dikurangi.
class DsSheen extends StatefulWidget {
  /// Membuat [DsSheen].
  const DsSheen({required this.child, this.borderRadius = 12, this.period = const Duration(milliseconds: 3200), super.key});

  /// Isi, mis. tombol.
  final Widget child;

  /// Radius sudut pemotong kilat; samakan dengan anak.
  final double borderRadius;

  /// Selang satu sapuan ke sapuan berikutnya.
  final Duration period;

  @override
  State<DsSheen> createState() => _DsSheenState();
}

class _DsSheenState extends State<DsSheen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DsMotion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (DsMotion.reduced(context)) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(painter: _SheenPainter(_c.value)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheenPainter extends CustomPainter {
  const _SheenPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Sapuan pada 35% pertama siklus; sisanya diam.
    if (t > 0.35) return;
    final k = t / 0.35;
    final x = -size.width * 0.4 + size.width * 1.8 * k;
    final rect = Rect.fromLTWH(x, -4, size.width * 0.28, size.height + 8);
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(rect.center.dx, rect.center.dy)
      ..skew(-0.35, 0)
      ..translate(-rect.center.dx, -rect.center.dy)
      ..drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.38), Colors.white.withValues(alpha: 0)],
          ).createShader(rect),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.t != t;
}
