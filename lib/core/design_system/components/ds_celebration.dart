import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Perayaan singkat: ledakan partikel dari satu titik dan tulisan hadiah
/// yang melayang naik. Dipasang di `Overlay` akar dan dilepas sendiri.
/// Tidak melakukan apa pun saat gerak dikurangi.
abstract final class DsCelebration {
  DsCelebration._();

  /// Memicu perayaan dari [origin] (koordinat layar, mis. pusat tombol).
  ///
  /// [label] ("+50 XP") ditulis pemanggil. [random] hanya untuk uji.
  static void burst(
    BuildContext context, {
    required Offset origin,
    String? label,
    int count = 24,
    math.Random? random,
  }) {
    if (DsMotion.reduced(context)) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BurstLayer(
        origin: origin,
        label: label,
        count: count,
        random: random ?? math.Random(),
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _Particle {
  _Particle({
    required this.dx,
    required this.dy,
    required this.endScale,
    required this.endRotation,
    required this.duration,
    this.glyph,
    this.round = false,
  });

  final double dx;
  final double dy;
  final double endScale;
  final double endRotation;
  final double duration;
  final String? glyph;
  final bool round;
}

class _BurstLayer extends StatefulWidget {
  const _BurstLayer({
    required this.origin,
    required this.count,
    required this.random,
    required this.onDone,
    this.label,
  });

  final Offset origin;
  final String? label;
  final int count;
  final math.Random random;
  final VoidCallback onDone;

  @override
  State<_BurstLayer> createState() => _BurstLayerState();
}

class _BurstLayerState extends State<_BurstLayer> with SingleTickerProviderStateMixin {
  static const _glyphs = ['🍃', '✨', '🪙', '🌰', '⭐'];

  late final AnimationController _controller = AnimationController(vsync: this, duration: DsMotion.burst);
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final r = widget.random;
    _particles = [
      for (var i = 0; i < widget.count; i++) _make(i, r),
    ];
    _controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  _Particle _make(int i, math.Random r) {
    final angle = 2 * math.pi * i / widget.count + (r.nextDouble() - 0.5) * 0.5;
    final velocity = 80 + r.nextDouble() * 90;
    final emoji = r.nextBool();
    return _Particle(
      dx: math.cos(angle) * velocity,
      dy: math.sin(angle) * velocity - 35,
      endScale: 0.8 + r.nextDouble() * 0.4,
      endRotation: r.nextDouble() * 360,
      duration: 900 + r.nextDouble() * 300,
      glyph: emoji ? _glyphs[r.nextInt(_glyphs.length)] : null,
      round: r.nextBool(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final shapeColors = [c.income, c.warning, c.heroAccent, c.heroAccentWarm, c.actionPrimary];
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final elapsedMs = _controller.value * DsMotion.burst.inMilliseconds;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < _particles.length; i++)
                  _particle(_particles[i], elapsedMs, shapeColors[i % shapeColors.length]),
                if (widget.label != null)
                  _label(
                    context,
                    _controller.value * DsMotion.burst.inMilliseconds / DsMotion.floatLabel.inMilliseconds,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _particle(_Particle p, double elapsedMs, Color shapeColor) {
    final q = Curves.easeOutQuart.transform((elapsedMs / p.duration).clamp(0, 1));
    final out = q <= 0.65;
    final s = out ? q / 0.65 : (q - 0.65) / 0.35;
    final dx = out ? p.dx * s : p.dx + (p.dx * 1.15 - p.dx) * s;
    final dy = out ? p.dy * s : p.dy + (p.dy + 45 - p.dy) * s;
    final scale = out ? 0.6 + (p.endScale - 0.6) * s : p.endScale + (0.2 - p.endScale) * s;
    final opacity = out ? 1 - 0.1 * s : 0.9 * (1 - s);
    final body = p.glyph != null
        ? Text(p.glyph!, style: const TextStyle(fontSize: 14))
        : Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: shapeColor,
              shape: p.round ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: p.round ? null : BorderRadius.circular(2),
            ),
          );
    return Positioned(
      left: widget.origin.dx + dx,
      top: widget.origin.dy + dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Opacity(
          opacity: opacity.clamp(0, 1),
          child: Transform.rotate(
            angle: p.endRotation * q * math.pi / 180,
            child: Transform.scale(scale: scale, child: body),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, double t) {
    final ds = context.ds;
    final c = ds.colors;
    final u = t.clamp(0, 1).toDouble();
    final y = dsKeyframes(u, [(0, 0), (0.2, -15), (1, -140)]);
    final scale = dsKeyframes(u, [(0, 0.85), (0.2, 1.15), (1, 0.9)]);
    final opacity = dsKeyframes(u, [(0, 0), (0.2, 1), (0.75, 0.95), (1, 0)]);
    return Positioned(
      left: widget.origin.dx,
      top: widget.origin.dy + y,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.warningContainer,
                borderRadius: DsRadius.badgeAll,
                border: Border.all(color: c.warning.withValues(alpha: 0.4)),
              ),
              child: Text(widget.label!, style: ds.typography.pixelLabel.copyWith(color: c.onWarningContainer)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Goyang singkat saat [trigger] bertambah (badge level setelah klaim):
/// membesar 18% sambil bergoyang lalu kembali (750ms). Diam saat gerak
/// dikurangi.
class DsJiggle extends StatefulWidget {
  /// Membuat jiggle.
  const DsJiggle({required this.trigger, required this.child, super.key});

  /// Naikkan angka ini untuk memutar animasi.
  final int trigger;

  /// Isi.
  final Widget child;

  @override
  State<DsJiggle> createState() => _DsJiggleState();
}

class _DsJiggleState extends State<DsJiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: DsMotion.jiggle);

  @override
  void didUpdateWidget(DsJiggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && !DsMotion.reduced(context)) {
      _controller.forward(from: 0);
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
        final u = _controller.value;
        final scale = dsKeyframes(u, [(0, 1), (0.2, 1.18), (0.4, 1.15), (0.6, 1.08), (0.8, 1.03), (1, 1)]);
        final angle = dsKeyframes(u, [(0, 0), (0.2, -4), (0.4, 4), (0.6, -2), (0.8, 1), (1, 0)]);
        return Transform.rotate(
          angle: angle * math.pi / 180,
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }
}

/// Pantulan singkat saat [trigger] berubah: mengecil dan berputar ke satu
/// sisi lalu membesar ke sisi lain dan kembali (450ms). Dipakai pada ikon
/// mata saat saldo disembunyikan. Diam saat gerak dikurangi.
class DsBounce extends StatefulWidget {
  /// Membuat pantulan.
  const DsBounce({required this.trigger, required this.child, super.key});

  /// Ubah nilai ini untuk memutar animasi (bukan saat pertama tampil).
  final int trigger;

  /// Isi.
  final Widget child;

  @override
  State<DsBounce> createState() => _DsBounceState();
}

class _DsBounceState extends State<DsBounce> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didUpdateWidget(DsBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && !DsMotion.reduced(context)) {
      _controller.forward(from: 0);
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
        final u = Curves.easeOutBack.transform(_controller.value);
        final scale = dsKeyframes(u, [(0, 1), (0.4, 0.8), (0.75, 1.2), (1, 1)]);
        final angle = dsKeyframes(u, [(0, 0), (0.4, -15), (0.75, 10), (1, 0)]);
        return Transform.rotate(angle: angle * math.pi / 180, child: Transform.scale(scale: scale, child: child));
      },
    );
  }
}

/// Goyang membal sekali tiap [trigger] berubah (acuan `wigglePop`, 0,42 dtk):
/// skala 0,94 → 1,1 → 1,04 → 1 sambil miring -4° lalu 3°. Diam saat gerak
/// dikurangi.
class DsWiggle extends StatefulWidget {
  /// Membuat goyangan.
  const DsWiggle({required this.trigger, required this.child, super.key});

  /// Naikkan untuk memutar goyangan.
  final int trigger;

  /// Yang digoyang.
  final Widget child;

  @override
  State<DsWiggle> createState() => _DsWiggleState();
}

class _DsWiggleState extends State<DsWiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(DsWiggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && !DsMotion.reduced(context)) {
      _controller.forward(from: 0);
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
      builder: (context, child) {
        final u = _controller.value;
        final scale = dsKeyframes(u, [(0, 0.94), (0.35, 1.1), (0.7, 1.04), (1, 1)]);
        final angle = dsKeyframes(u, [(0, 0), (0.35, -4), (0.7, 3), (1, 0)]);
        return Transform.rotate(
          angle: angle * math.pi / 180,
          child: Transform.scale(scale: _controller.isAnimating ? scale : 1, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Goyang halus berulang bergantian khas mode atur (acuan `jiggle-even` dan
/// `jiggle-odd`): miring ±1,2° tiap 0,21–0,23 dtk; genap dan ganjil berlawanan
/// arah. Diam saat gerak dikurangi.
class DsJiggleLoop extends StatefulWidget {
  /// Membuat goyangan berulang untuk item ke-[index].
  const DsJiggleLoop({required this.index, required this.child, super.key});

  /// Indeks item; genap dan ganjil bergoyang berlawanan.
  final int index;

  /// Yang digoyang.
  final Widget child;

  @override
  State<DsJiggleLoop> createState() => _DsJiggleLoopState();
}

class _DsJiggleLoopState extends State<DsJiggleLoop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.index.isEven ? 230 : 210),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DsMotion.reduced(context)) {
      _controller
        ..stop()
        ..value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sign = widget.index.isEven ? 1.0 : -1.0;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final u = (_controller.value - 0.5) * 2;
        return Transform.rotate(angle: sign * u * 1.2 * math.pi / 180, child: child);
      },
      child: widget.child,
    );
  }
}
