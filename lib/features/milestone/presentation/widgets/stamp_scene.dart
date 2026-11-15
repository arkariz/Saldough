import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';

/// Adegan di atas Buku Stempel (gaya Kaya, rupa buku-stempel §9, hanya di
/// dalam layar ini): latar gradasi lembut, daun melayang pelan, dua kilau,
/// Tanuki yang bernapas dan melompat saat [cheer] bertambah, dan balon yang
/// mengetik [message] per huruf.
///
/// Satu `Ticker` untuk daun dan kilau. Gerak dikurangi: tanpa daun, kilau,
/// napas, dan lompat; balon langsung penuh. Balon `liveRegion` supaya pembaca
/// layar membacakan tiap pesan baru.
class StampScene extends StatelessWidget {
  /// Membuat [StampScene].
  const StampScene({required this.message, required this.cheer, super.key});

  /// Kalimat balon Tanuki.
  final String message;

  /// Naik tiap ada tindakan; memicu lompat Tanuki.
  final int cheer;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final reduced = DsMotion.reduced(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.3,
            colors: [Color.alphaBlend(c.actionPrimary.withValues(alpha: 0.14), c.surfaceCard), c.surfaceCard],
            stops: const [0, 0.72],
          ),
          border: Border.all(color: c.outlineSubtle),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            if (!reduced) const Positioned.fill(child: _Drift()),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Mascot(cheer: cheer),
                  const SizedBox(width: 10),
                  Expanded(child: _Bubble(message: message)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Daun melayang dan kilau, digambar satu `CustomPainter` dengan satu `Ticker`.
class _Drift extends StatefulWidget {
  const _Drift();

  @override
  State<_Drift> createState() => _DriftState();
}

class _DriftState extends State<_Drift> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _DriftPainter(_c.value, c.stampSeal, c.stampGold)),
      ),
    );
  }
}

class _DriftPainter extends CustomPainter {
  const _DriftPainter(this.t, this.leaf, this.gold);

  final double t;
  final Color leaf;
  final Color gold;

  // Posisi x (0–1), fase awal (0–1), putaran per siklus, ukuran, alfa; enam daun.
  static const _leaves = [
    (0.08, 0.00, 1.0, 12.0, 0.35),
    (0.26, 0.45, 0.6, 9.0, 0.30),
    (0.47, 0.20, 1.4, 12.0, 0.35),
    (0.66, 0.70, 0.8, 9.0, 0.30),
    (0.82, 0.35, 1.2, 12.0, 0.35),
    (0.94, 0.85, 0.7, 9.0, 0.30),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (x, phase, spin, sz, alpha) in _leaves) {
      final p = (t + phase) % 1;
      final fade = p < 0.15 ? p / 0.15 : (p > 0.85 ? (1 - p) / 0.15 : 1.0);
      final dx = x * size.width + math.sin(p * math.pi * 2) * 14;
      final dy = -20 + p * (size.height + 40);
      canvas
        ..save()
        ..translate(dx, dy)
        ..rotate(p * math.pi * 2 * spin);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(sz, 0, sz, sz)
        ..quadraticBezierTo(0, sz, 0, 0);
      canvas
        ..drawPath(path, Paint()..color = leaf.withValues(alpha: alpha * fade))
        ..restore();
    }
    // Dua kilau emas berkedip bergantian.
    for (final (i, pos) in [(0, const Offset(0.62, 0.2)), (1, const Offset(0.9, 0.55))]) {
      final k = ((t * 14 / 2.4) + i * 0.5) % 1;
      final scale = math.sin(k * math.pi);
      if (scale <= 0.02) continue;
      final center = Offset(pos.dx * size.width, pos.dy * size.height);
      final r = 5 * scale;
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(k * math.pi / 2);
      final star = Path()
        ..moveTo(0, -r)
        ..lineTo(r * 0.24, -r * 0.24)
        ..lineTo(r, 0)
        ..lineTo(r * 0.24, r * 0.24)
        ..lineTo(0, r)
        ..lineTo(-r * 0.24, r * 0.24)
        ..lineTo(-r, 0)
        ..lineTo(-r * 0.24, -r * 0.24)
        ..close();
      canvas
        ..drawPath(star, Paint()..color = gold.withValues(alpha: scale))
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_DriftPainter old) => old.t != t;
}

/// Tanuki 76: bernapas pelan, melompat (`cheer`, 900 ms) tiap [cheer] bertambah.
class _Mascot extends StatefulWidget {
  const _Mascot({required this.cheer});

  final int cheer;

  @override
  State<_Mascot> createState() => _MascotState();
}

class _MascotState extends State<_Mascot> with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  late final AnimationController _jump = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DsMotion.reduced(context)) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_Mascot old) {
    super.didUpdateWidget(old);
    if (widget.cheer != old.cheer && !DsMotion.reduced(context)) _jump.forward(from: 0);
  }

  @override
  void dispose() {
    _breath.dispose();
    _jump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: t.stamps.kaya.mascot,
      image: true,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breath, _jump]),
        builder: (context, child) {
          final b = Curves.easeInOut.transform(_breath.value);
          final j = _jump.value;
          // Tekan -> lompat -> mendarat (acuan `cheer`).
          final jumpY = dsKeyframes(j, [(0, 0), (0.18, 2), (0.45, -22), (0.65, -18), (0.85, 0), (1, 0)]);
          final tilt = dsKeyframes(j, [(0, 0), (0.45, -8), (0.65, 8), (1, 0)]) * math.pi / 180;
          final sx = dsKeyframes(j, [(0, 1), (0.18, 1.12), (0.85, 1.08), (1, 1)]);
          final sy = dsKeyframes(j, [(0, 1), (0.18, 0.86), (0.85, 0.92), (1, 1)]);
          return Transform.translate(
            offset: Offset(0, -4 * b + jumpY),
            child: Transform.rotate(
              angle: tilt,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.diagonal3Values(sx, sy * (1 + 0.03 * b), 1),
                child: child,
              ),
            ),
          );
        },
        child: SvgPicture.asset(ClayIcons.mascot, width: 76, height: 76),
      ),
    );
  }
}

/// Balon Tanuki yang mengetik [message] per huruf (16 ms per huruf).
class _Bubble extends StatefulWidget {
  const _Bubble({required this.message});

  final String message;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  Timer? _timer;
  int _shown = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer == null && _shown == 0) _restart();
  }

  @override
  void didUpdateWidget(_Bubble old) {
    super.didUpdateWidget(old);
    if (old.message != widget.message) _restart();
  }

  void _restart() {
    _timer?.cancel();
    if (DsMotion.reduced(context)) {
      _shown = widget.message.length;
      return;
    }
    _shown = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      setState(() => _shown = math.min(_shown + 1, widget.message.length));
      if (_shown >= widget.message.length) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Semantics(
      liveRegion: true,
      label: widget.message,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: BoxDecoration(
          color: c.surfaceCard,
          border: Border.all(color: c.outlineSubtle),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.stamps.kaya.mascot.toUpperCase(),
              style: ds.typography.pixelCaption.copyWith(color: c.actionPrimary),
            ),
            const SizedBox(height: 2),
            // Satu `Text.rich`: huruf yang sudah diketik tampil, sisanya transparan,
            // sehingga tinggi balon tetap dan tidak melompat saat mengetik.
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: widget.message.substring(0, _shown.clamp(0, widget.message.length))),
                  TextSpan(
                    text: widget.message.substring(_shown.clamp(0, widget.message.length)),
                    style: const TextStyle(color: Colors.transparent),
                  ),
                ],
              ),
              style: ds.typography.bodyMd,
            ),
          ],
        ),
      ),
    );
  }
}
