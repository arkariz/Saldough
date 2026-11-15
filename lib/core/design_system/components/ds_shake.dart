import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';

/// Getar layar singkat tiap [trigger] bertambah (rupa buku periode, "cap"):
/// bergeser ±[amplitude] dp ke samping selama 420 ms dengan peluruhan. Diam saat
/// gerak dikurangi. Pembungkus tidak mengubah ukuran anaknya.
class DsShake extends StatefulWidget {
  /// Membuat [DsShake].
  const DsShake({required this.trigger, required this.child, this.amplitude = 5, super.key});

  /// Naik untuk memicu getar.
  final int trigger;

  /// Anak yang bergetar.
  final Widget child;

  /// Simpangan terjauh, dp.
  final double amplitude;

  @override
  State<DsShake> createState() => _DsShakeState();
}

class _DsShakeState extends State<DsShake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(DsShake old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger && !DsMotion.reduced(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Transform.translate(
      offset: Offset(math.sin(_c.value * math.pi * 6) * widget.amplitude * (1 - _c.value), 0),
      child: child,
    ),
    child: widget.child,
  );
}
