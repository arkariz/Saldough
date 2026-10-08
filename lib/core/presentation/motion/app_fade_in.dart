import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:saldough/core/presentation/motion/motion_policy.dart';

/// Kemunculan antarmuka: pudar 250ms dengan kurva standar, dimulai sesudah
/// [delay] saat [play] true (design system bagian Gerak, ADR-034). Tanpa
/// gerak bertangga; itu hanya untuk maskot.
///
/// Saat "kurangi gerakan" aktif, [child] langsung tampil utuh.
class AppFadeIn extends StatefulWidget {
  /// Membuat [AppFadeIn] untuk [child].
  const AppFadeIn({
    required this.child,
    this.play = true,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 250),
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

  @override
  State<AppFadeIn> createState() => _AppFadeInState();
}

class _AppFadeInState extends State<AppFadeIn>
    with SingleTickerProviderStateMixin {
  // Jeda dimasukkan ke durasi controller (lewat `Interval`), bukan
  // `Future.delayed`, supaya tidak ada timer yang menggantung di uji.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybePlay();
  }

  @override
  void didUpdateWidget(AppFadeIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybePlay();
  }

  void _maybePlay() {
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
    final total = widget.delay + widget.duration;
    final start = total == Duration.zero
        ? 0.0
        : widget.delay.inMicroseconds / total.inMicroseconds;
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: Interval(start, 1, curve: Curves.easeOut),
      ),
      child: widget.child,
    );
  }
}
