import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_badge.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Jenis [DsPulse].
enum DsPulseKind {
  /// Cincin merah melebar: tagihan jatuh tempo (2 dtk).
  alert,

  /// Cahaya emas membesar-mengecil: hadiah aktif (2,5 dtk).
  gold,
}

/// Membungkus [child] (biasanya [DsBadge]) dengan denyut berulang. Tidak
/// berdenyut saat gerak dikurangi. Pakai hemat: satu-dua per layar.
class DsPulse extends StatefulWidget {
  /// Membuat denyut.
  const DsPulse({required this.child, this.kind = DsPulseKind.alert, this.borderRadius = DsRadius.badgeAll, super.key});

  /// Isi.
  final Widget child;

  /// Jenis denyut.
  final DsPulseKind kind;

  /// Sudut bayangan, samakan dengan sudut [child].
  final BorderRadius borderRadius;

  @override
  State<DsPulse> createState() => _DsPulseState();
}

class _DsPulseState extends State<DsPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.kind == DsPulseKind.alert ? const Duration(seconds: 1) : const Duration(milliseconds: 1250),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DsMotion.reduced(context)) {
      _controller
        ..stop()
        ..value = 0;
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
    final c = context.ds.colors;
    if (DsMotion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final shadow = switch (widget.kind) {
          DsPulseKind.alert => BoxShadow(color: c.error.withValues(alpha: 0.4 * (1 - t)), spreadRadius: 4 * t),
          DsPulseKind.gold => BoxShadow(
            color: c.warning.withValues(alpha: 0.25 + 0.3 * t),
            blurRadius: 8 + 8 * t,
          ),
        };
        return DecoratedBox(
          decoration: BoxDecoration(borderRadius: widget.borderRadius, boxShadow: [shadow]),
          child: child,
        );
      },
    );
  }
}

/// Jenis [DsIdleMotion].
enum DsIdleKind {
  /// Naik 3px sambil miring 6° lalu kembali (3,2 dtk): daun.
  sway,

  /// Naik 2,5px lalu kembali (2,6 dtk): koin.
  float,
}

/// Gerak diam yang pelan dan berulang untuk hiasan kecil (daun, koin).
/// Diam saat gerak dikurangi.
class DsIdleMotion extends StatefulWidget {
  /// Membuat gerak diam.
  const DsIdleMotion({required this.child, this.kind = DsIdleKind.sway, super.key});

  /// Isi, biasanya ikon atau emoji kecil.
  final Widget child;

  /// Jenis gerak.
  final DsIdleKind kind;

  @override
  State<DsIdleMotion> createState() => _DsIdleMotionState();
}

class _DsIdleMotionState extends State<DsIdleMotion> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.kind == DsIdleKind.sway ? const Duration(milliseconds: 1600) : const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DsMotion.reduced(context)) {
      _controller
        ..stop()
        ..value = 0;
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
    if (DsMotion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return switch (widget.kind) {
          DsIdleKind.sway => Transform.translate(
            offset: Offset(0, -3 * t),
            child: Transform.rotate(angle: 6 * math.pi / 180 * t, child: child),
          ),
          DsIdleKind.float => Transform.translate(offset: Offset(0, -2.5 * t), child: child),
        };
      },
    );
  }
}
