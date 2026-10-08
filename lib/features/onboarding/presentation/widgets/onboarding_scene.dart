import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/motion/motion.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Jumlah layar onboarding: OB-1..OB-4 dan layar akhir.
const onboardingSlideCount = 5;

/// Judul dan isi layar onboarding ke-[index] (ART_BRIEF §3).
(String, String) onboardingText(int index) => switch (index) {
  0 => (t.onboarding.page1Title, t.onboarding.page1Body),
  1 => (t.onboarding.page2Title, t.onboarding.page2Body),
  2 => (t.onboarding.page3Title, t.onboarding.page3Body),
  3 => (t.onboarding.page4Title, t.onboarding.page4Body),
  _ => (t.onboarding.finalTitle, t.onboarding.finalBody),
};

/// Adegan satu layar onboarding: ilustrasi pemilik yang "bernapas" ditambah
/// lapisan ikon pixel yang bergerak (ADR-021 §3.7).
///
/// Hanya adegan [active] yang bergerak; saat "kurangi gerakan" aktif,
/// semuanya diam di keadaan akhirnya. Warna arah uang (hijau/merah/biru)
/// hanya dipakai di OB-3 (ADR-016).
class OnboardingScene extends StatefulWidget {
  /// Membuat [OnboardingScene].
  const OnboardingScene({required this.index, required this.active, super.key});

  /// Urutan layar.
  final int index;

  /// True saat layar ini yang tampil.
  final bool active;

  @override
  State<OnboardingScene> createState() => _OnboardingSceneState();
}

class _OnboardingSceneState extends State<OnboardingScene> with SingleTickerProviderStateMixin {
  /// Satu jam bersama untuk semua gerak berulang di adegan ini.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// True sesudah adegan pernah aktif — kemunculan hanya diputar sekali.
  bool _entered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(OnboardingScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.active) _entered = true;
    final reduced = MotionPolicy.reduced(context);
    if (reduced) {
      _loop
        ..stop()
        ..value = 1;
    } else if (widget.active && !_loop.isAnimating) {
      unawaited(_loop.repeat());
    } else if (!widget.active) {
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final moving = widget.active && !MotionPolicy.reduced(context);
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: PixelSparkle(
              color: colors.warning.withValues(alpha: 0.7),
              count: widget.index == 4 ? 12 : 6,
              seed: 11 + widget.index,
              enabled: moving,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12, vertical: AppSpacing.space2),
            child: PixelBob(
              enabled: moving,
              child: Image.asset(
                'assets/illustration/onboarding_${widget.index + 1}.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
              ),
            ),
          ),
          ..._overlay(context),
        ],
      ),
    );
  }

  List<Widget> _overlay(BuildContext context) {
    final colors = context.appColors;
    final play = _entered;
    final moving = widget.active && !MotionPolicy.reduced(context);
    Widget pop(Alignment at, Widget child, int delayMs, {double phase = 0}) => Align(
      alignment: at,
      child: PixelPop(
        play: play,
        delay: Duration(milliseconds: delayMs),
        child: PixelBob(enabled: moving, amplitude: 3, phase: phase, child: child),
      ),
    );

    switch (widget.index) {
      // OB-1: pratinjau tiga layar berikutnya — dompet, transaksi, rencana.
      case 0:
        return [
          pop(const Alignment(-0.95, -0.55), const _Tile(IconKey.wallets), 300),
          pop(const Alignment(0.95, -0.15), const _Tile(IconKey.transactions), 550, phase: 0.33),
          pop(const Alignment(-0.95, 0.4), const _Tile(IconKey.calendar), 800, phase: 0.66),
        ];
      // OB-2: tiga jenis dompet jatuh ke tempatnya, lalu mengalir ke total.
      case 1:
        return [
          Positioned.fill(
            child: _FlowLine(
              loop: _loop,
              from: const Alignment(0.95, 0.7),
              to: const Alignment(0.95, -0.7),
              color: colors.ink,
            ),
          ),
          pop(const Alignment(0.95, -0.72), const _Tile(IconKey.wallets, size: 48), 900),
          for (final (i, icon) in [IconKey.walletBank, IconKey.walletEwallet, IconKey.walletCash].indexed)
            Align(
              alignment: Alignment(0.95, -0.15 + i * 0.4),
              child: _DropIn(
                play: play,
                delay: Duration(milliseconds: 250 + i * 200),
                child: _Tile(icon),
              ),
            ),
        ];
      // OB-3: masuk menambah, keluar mengurangi, transfer hanya berpindah.
      case 2:
        return [
          Positioned.fill(
            child: _Travel(
              loop: _loop,
              from: const Alignment(-0.95, -0.95),
              to: const Alignment(-0.95, -0.45),
              child: _Token(colors.positive),
            ),
          ),
          const Align(alignment: Alignment(-0.95, -0.4), child: _Tile(IconKey.income)),
          const Align(alignment: Alignment(-0.95, 0.2), child: _Tile(IconKey.expense)),
          Positioned.fill(
            child: _Travel(
              loop: _loop,
              from: const Alignment(-0.95, 0.3),
              to: const Alignment(-0.95, 0.85),
              child: _Token(colors.ink),
            ),
          ),
          const Align(alignment: Alignment(0.95, -0.3), child: _Tile(IconKey.walletBank)),
          const Align(alignment: Alignment(0.95, 0.5), child: _Tile(IconKey.walletCash)),
          Positioned.fill(
            child: _Travel(
              loop: _loop,
              from: const Alignment(0.95, -0.1),
              to: const Alignment(0.95, 0.3),
              pingPong: true,
              child: _Token(colors.ink2),
            ),
          ),
        ];
      // OB-4: rencana terisi segmen demi segmen, pos dicentang berurutan.
      case 3:
        return [
          for (final (i, x) in [-0.6, 0.0, 0.6].indexed)
            pop(
              Alignment(x, -0.95),
              _Tile(IconKey.check, size: 36, tint: colors.ink),
              300 + i * 250,
              phase: i / 3,
            ),
          Align(
            alignment: const Alignment(0, 0.95),
            child: _SegmentFill(loop: _loop),
          ),
        ];
      // Akhir: maskot menyambut, kilau lebih ramai.
      default:
        return [
          pop(const Alignment(-0.9, 0.6), const _Tile(IconKey.record), 400),
        ];
    }
  }
}

/// Kotak ikon pixel kecil bergaris tepi dan berbayangan keras.
class _Tile extends StatelessWidget {
  const _Tile(this.icon, {this.size = 40, this.tint});

  final IconKey icon;
  final double size;

  /// Mewarnai ulang ikon satu warna — mis. centang hijau di luar OB-3, yang
  /// melanggar "hijau hanya untuk uang masuk" (ADR-016).
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
      ),
      child: tint == null
          ? AppIcon(icon, size: size * 0.55)
          : ColorFiltered(
              colorFilter: ColorFilter.mode(tint!, BlendMode.srcIn),
              child: AppIcon(icon, size: size * 0.55),
            ),
    );
  }
}

/// Token uang kecil — kotak piksel berwarna arah uang (hanya di OB-3).
class _Token extends StatelessWidget {
  const _Token(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
      ),
    );
  }
}

/// Memindahkan [child] dari [from] ke [to] mengikuti [loop], bertangga.
/// [pingPong] membuatnya bolak-balik.
class _Travel extends StatelessWidget {
  const _Travel({required this.loop, required this.from, required this.to, required this.child, this.pingPong = false});

  final Animation<double> loop;
  final Alignment from;
  final Alignment to;
  final Widget child;
  final bool pingPong;

  static const _steps = SteppedCurve(8);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      child: child,
      builder: (context, child) {
        final raw = loop.value;
        final t = pingPong ? (raw < 0.5 ? raw * 2 : 2 - raw * 2) : raw;
        return Align(alignment: Alignment.lerp(from, to, _steps.transform(t))!, child: child);
      },
    );
  }
}

/// Garis putus-putus piksel dari [from] ke [to] yang mengalir mengikuti
/// [loop] — "saldo mengalir ke total".
class _FlowLine extends StatelessWidget {
  const _FlowLine({required this.loop, required this.from, required this.to, required this.color});

  final Animation<double> loop;
  final Alignment from;
  final Alignment to;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _FlowLinePainter(loop: loop, from: from, to: to, color: color),
      ),
    );
  }
}

class _FlowLinePainter extends CustomPainter {
  _FlowLinePainter({required this.loop, required this.from, required this.to, required this.color})
    : super(repaint: loop);

  final Animation<double> loop;
  final Alignment from;
  final Alignment to;
  final Color color;

  static const _dash = 6.0;
  static const _gap = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Ujung garis di tengah kotak ikon; dipotong 24px di kedua ujung supaya
    // tidak menembus kotaknya.
    final a = from.withinRect(Offset.zero & size);
    final b = to.withinRect(Offset.zero & size);
    final length = (b - a).distance;
    if (length <= 48) return;
    final direction = (b - a) / length;
    final paint = Paint()..color = color.withValues(alpha: 0.55);
    const period = _dash + _gap;
    final shift = snapToPixelGrid(loop.value * period * 4 % period);
    for (var d = 24 + shift; d < length - 24; d += period) {
      final p = a + direction * d;
      canvas.drawRect(Rect.fromCenter(center: p, width: 4, height: _dash), paint);
    }
  }

  @override
  bool shouldRepaint(_FlowLinePainter oldDelegate) => oldDelegate.color != color;
}

/// Jatuh bertangga dari atas ke tempatnya, sekali, sesudah [delay].
class _DropIn extends StatefulWidget {
  const _DropIn({required this.play, required this.delay, required this.child});

  final bool play;
  final Duration delay;
  final Widget child;

  @override
  State<_DropIn> createState() => _DropInState();
}

class _DropInState extends State<_DropIn> with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 420);
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.delay + _duration);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStart();
  }

  @override
  void didUpdateWidget(_DropIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeStart();
  }

  void _maybeStart() {
    if (!widget.play || _started) return;
    _started = true;
    if (MotionPolicy.reduced(context)) {
      _controller.value = 1;
    } else {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = (widget.delay + _duration).inMicroseconds;
    final curve = Interval(widget.delay.inMicroseconds / total, 1, curve: const SteppedCurve(6, curve: Curves.easeIn));
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = curve.transform(_controller.value);
        return Opacity(
          opacity: t == 0 ? 0 : 1,
          child: Transform.translate(offset: Offset(0, snapToPixelGrid((1 - t) * -56)), child: child),
        );
      },
    );
  }
}

/// Bilah bersegmen yang terisi segmen demi segmen lalu mulai lagi — pola
/// bilah anggaran (ADR-020: warna sehat = teks utama).
class _SegmentFill extends StatelessWidget {
  const _SegmentFill({required this.loop});

  final Animation<double> loop;

  static const _segments = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        // Delapan frame: enam segmen terisi satu per satu, lalu diam dua frame.
        final filled = (loop.value * (_segments + 2)).floor().clamp(0, _segments);
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: colors.surface,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _segments; i++)
                Container(
                  width: 22,
                  height: 12,
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
                  color: i < filled ? colors.ink : colors.line,
                ),
            ],
          ),
        );
      },
    );
  }
}
