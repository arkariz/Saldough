import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';

/// Muncul sekali saat pertama tampil: pudar masuk sambil naik pelan. [index]
/// menunda tiap anak 60 ms (maksimal 8 langkah) supaya daftar muncul
/// berurutan. Saat gerak dikurangi, langsung tampil.
class DsReveal extends StatefulWidget {
  /// Membuat [DsReveal].
  const DsReveal({required this.child, this.index = 0, super.key});

  /// Isi.
  final Widget child;

  /// Urutan di daftar (0 = tanpa tunda).
  final int index;

  @override
  State<DsReveal> createState() => _DsRevealState();
}

class _DsRevealState extends State<DsReveal> with SingleTickerProviderStateMixin {
  static const _step = Duration(milliseconds: 60);
  static const _body = Duration(milliseconds: 420);

  late final AnimationController _controller = AnimationController(vsync: this, duration: _body);
  Timer? _delay;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (DsMotion.reduced(context)) {
      _controller.value = 1;
      return;
    }
    final wait = _step * widget.index.clamp(0, 8);
    if (wait == Duration.zero) {
      _controller.forward();
    } else {
      _delay = Timer(wait, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: DsMotion.easeOutExpo);
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(curved),
        child: widget.child,
      ),
    );
  }
}
