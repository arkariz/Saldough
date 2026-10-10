import 'package:flutter/widgets.dart';
import 'package:saldough/core/presentation/motion/motion_policy.dart';
import 'package:saldough/core/presentation/motion/stepped_curve.dart';

/// Kemunculan bertangga: skala 0 → 1,15 → 1 disertai muncul, dimulai
/// sesudah [delay] saat [play] true (ADR-021 §3.7).
///
/// Saat "kurangi gerakan" aktif, [child] langsung tampil utuh.
class PixelPop extends StatefulWidget {
  /// Membuat [PixelPop] untuk [child].
  const PixelPop({
    required this.child,
    this.play = true,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 360),
    this.alignment = Alignment.center,
    super.key,
  });

  /// Widget yang muncul.
  final Widget child;

  /// False menahan [child] tersembunyi; berubah ke true memulai animasi.
  final bool play;

  /// Jeda sebelum mulai.
  final Duration delay;

  /// Lama animasi.
  final Duration duration;

  /// Titik pusat skala.
  final Alignment alignment;

  @override
  State<PixelPop> createState() => _PixelPopState();
}

class _PixelPopState extends State<PixelPop> with SingleTickerProviderStateMixin {
  // Jeda dimasukkan ke dalam durasi controller (lewat `Interval`), bukan
  // `Future.delayed`, supaya tidak ada timer yang menggantung di uji.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  bool _scheduled = false;

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 1.15), weight: 70),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1), weight: 30),
  ]);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybePlay();
  }

  @override
  void didUpdateWidget(PixelPop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybePlay();
  }

  void _maybePlay() {
    if (!widget.play || _scheduled) return;
    _scheduled = true;
    if (MotionPolicy.reduced(context)) {
      _controller.value = 1;
      return;
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = (widget.delay + widget.duration).inMicroseconds;
    final start = total == 0 ? 0.0 : widget.delay.inMicroseconds / total;
    final stepped = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: const SteppedCurve(6)),
    );
    return AnimatedBuilder(
      animation: stepped,
      child: widget.child,
      builder: (context, child) {
        final t = stepped.value;
        return Opacity(
          opacity: t == 0 ? 0 : 1,
          child: Transform.scale(
            scale: _scale.transform(t),
            alignment: widget.alignment,
            child: child,
          ),
        );
      },
    );
  }
}
