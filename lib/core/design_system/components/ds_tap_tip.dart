import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Menampilkan [message] di atas [child] selama 2,4 dtk saat [child]
/// diketuk, dengan geser dan pudar. Tidak mengambil alih ketukan: bila
/// [child] sendiri bisa diketuk, keduanya berjalan.
class DsTapTip extends StatefulWidget {
  /// Membuat tooltip ketuk.
  const DsTapTip({required this.message, required this.child, super.key});

  /// Teks tooltip.
  final String message;

  /// Isi yang diketuk.
  final Widget child;

  @override
  State<DsTapTip> createState() => _DsTapTipState();
}

class _DsTapTipState extends State<DsTapTip> {
  bool _visible = false;
  Timer? _timer;

  void _show() {
    _timer?.cancel();
    setState(() => _visible = true);
    _timer = Timer(DsMotion.tip, () {
      if (mounted) setState(() => _visible = false);
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
    final duration = DsMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 300);
    return Listener(
      onPointerUp: (_) => _show(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedSlide(
                offset: Offset(0, _visible ? -0.25 : 0),
                duration: duration,
                curve: DsMotion.curve,
                child: AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: duration,
                  child: Center(
                    child: Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: ds.colors.textPrimary, borderRadius: DsRadius.badgeAll),
                        child: Text(
                          widget.message,
                          style: ds.typography.pixelLabel.copyWith(color: ds.colors.surfaceCanvas),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
