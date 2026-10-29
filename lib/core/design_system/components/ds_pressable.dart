import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
import 'package:saldough/core/design_system/tokens/ds_opacity.dart';

/// Dasar semua bagian yang bisa diketuk di design system baru: mengecil
/// sedikit saat ditekan (150ms), memberi tahu [builder] apakah sedang
/// ditekan, dan memasang semantik tombol.
///
/// [onPressed] `null` membuatnya nonaktif: tidak bereaksi dan pudar
/// ([DsOpacity.disabled]) bila [dimWhenDisabled].
class DsPressable extends StatefulWidget {
  /// Membuat [DsPressable].
  const DsPressable({
    required this.builder,
    required this.onPressed,
    this.pressedScale = DsMotion.pressScale,
    this.semanticLabel,
    this.dimWhenDisabled = true,
    super.key,
  });

  /// Isi; `pressed` benar selama jari menekan.
  // Pola builder Flutter (seperti `ValueWidgetBuilder`).
  // ignore: avoid_positional_boolean_parameters
  final Widget Function(BuildContext context, bool pressed) builder;

  /// Dipanggil saat diketuk; `null` menonaktifkan.
  final VoidCallback? onPressed;

  /// Skala saat ditekan.
  final double pressedScale;

  /// Label pembaca layar. Bila `null`, teks di dalam isi yang dibacakan.
  final String? semanticLabel;

  /// Pudarkan saat nonaktif.
  final bool dimWhenDisabled;

  @override
  State<DsPressable> createState() => _DsPressableState();
}

class _DsPressableState extends State<DsPressable> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: Opacity(
        opacity: !_enabled && widget.dimWhenDisabled ? DsOpacity.disabled : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          child: AnimatedScale(
            scale: _pressed && !reduceMotion ? widget.pressedScale : 1,
            duration: DsMotion.standard,
            curve: DsMotion.curve,
            child: widget.builder(context, _pressed),
          ),
        ),
      ),
    );
  }
}
