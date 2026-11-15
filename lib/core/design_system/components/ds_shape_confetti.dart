import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';

/// Konfeti buku periode (rupa D5/D6): **daun hijau, koin emas, dan bintang
/// kuning** yang meledak dari satu titik, berputar, jatuh oleh gravitasi, lalu
/// memudar. Satu `Ticker` dan satu `CustomPainter` untuk seluruh partikel;
/// dipasang di `Overlay` akar dan dilepas sendiri. Paling banyak 44 partikel
/// per ledakan (batas kinerja perangkat kelas bawah). Tidak melakukan apa pun
/// saat gerak dikurangi.
///
/// Hanya untuk layar yang dibuka pengguna (Buku Periode, Buku Stempel; G-4,
/// BP-13). Tidak dipakai pada perayaan yang muncul sendiri.
abstract final class DsShapeConfetti {
  DsShapeConfetti._();

  /// Batas partikel per ledakan.
  static const int maxParticles = 44;

  /// Meledakkan konfeti dari [origin] (koordinat layar). [random] hanya untuk uji.
  static void burst(BuildContext context, {required Offset origin, int count = 24, math.Random? random}) {
    if (DsMotion.reduced(context)) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final colors = context.ds.colors;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Burst(
        origin: origin,
        count: math.min(count, maxParticles),
        random: random ?? math.Random(),
        leaf: colors.stampSeal,
        gold: colors.stampGold,
        goldDeep: colors.stampGoldDeep,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

enum _Shape { leaf, coin, star }

class _Particle {
  _Particle(math.Random r, this.shape)
    : angle = r.nextDouble() * math.pi * 2,
      speed = 120 + r.nextDouble() * 300,
      spin = (r.nextDouble() - 0.5) * 12,
      size = 6 + r.nextDouble() * 6,
      life = 1.2 + r.nextDouble() * 0.6;

  final _Shape shape;
  final double angle;
  final double speed;
  final double spin;
  final double size;
  final double life;
}

class _Burst extends StatefulWidget {
  const _Burst({
    required this.origin,
    required this.count,
    required this.random,
    required this.leaf,
    required this.gold,
    required this.goldDeep,
    required this.onDone,
  });

  final Offset origin;
  final int count;
  final math.Random random;
  final Color leaf;
  final Color gold;
  final Color goldDeep;
  final VoidCallback onDone;

  @override
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  late final List<_Particle> _particles = [
    for (var i = 0; i < widget.count; i++) _Particle(widget.random, _Shape.values[i % 3]),
  ];
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox.expand(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(
            t: _c.value * 1.8,
            origin: widget.origin,
            particles: _particles,
            leaf: widget.leaf,
            gold: widget.gold,
            goldDeep: widget.goldDeep,
          ),
        ),
      ),
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.t,
    required this.origin,
    required this.particles,
    required this.leaf,
    required this.gold,
    required this.goldDeep,
  });

  /// Detik sejak ledakan.
  final double t;
  final Offset origin;
  final List<_Particle> particles;
  final Color leaf;
  final Color gold;
  final Color goldDeep;

  static const double _gravity = 576; // 0,16 px/bingkai² pada 60 bps

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (t > p.life) continue;
      final pos = origin + Offset(math.cos(p.angle) * p.speed * t, math.sin(p.angle) * p.speed * t + 0.5 * _gravity * t * t);
      final fade = t < p.life * 0.65 ? 1.0 : (1 - (t - p.life * 0.65) / (p.life * 0.35)).clamp(0.0, 1.0);
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..rotate(p.spin * t);
      final s = p.size;
      switch (p.shape) {
        case _Shape.leaf:
          canvas.drawPath(
            Path()
              ..moveTo(0, 0)
              ..quadraticBezierTo(s, 0, s, s)
              ..quadraticBezierTo(0, s, 0, 0),
            Paint()..color = leaf.withValues(alpha: 0.9 * fade),
          );
        case _Shape.coin:
          canvas
            ..drawCircle(Offset.zero, s * 0.55, Paint()..color = goldDeep.withValues(alpha: fade))
            ..drawCircle(Offset(-s * 0.1, -s * 0.1), s * 0.38, Paint()..color = gold.withValues(alpha: fade));
        case _Shape.star:
          canvas.drawPath(_star(s * 0.7), Paint()..color = gold.withValues(alpha: fade));
      }
      canvas.restore();
    }
  }

  Path _star(double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final point = Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
