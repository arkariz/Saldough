import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';

/// Ilustrasi keadaan kosong yang hidup terus: ikon clay utama melayang di
/// atas cahaya yang berdenyut, dua cincin melebar bergantian, dan ikon
/// pengiring ([orbit], maksimal tiga) yang mengambang bergantian di
/// sekelilingnya. Semua gerak berhenti saat gerak dikurangi; hiasan tidak
/// dibacakan pembaca layar.
class DsEmptyHero extends StatefulWidget {
  /// Membuat [DsEmptyHero].
  const DsEmptyHero({required this.asset, this.orbit = const [], this.size = 128, super.key});

  /// Ikon clay utama.
  final String asset;

  /// Ikon clay pengiring.
  final List<String> orbit;

  /// Sisi kotak ilustrasi.
  final double size;

  @override
  State<DsEmptyHero> createState() => _DsEmptyHeroState();
}

class _DsEmptyHeroState extends State<DsEmptyHero> with SingleTickerProviderStateMixin {
  static const _period = Duration(milliseconds: 3200);

  late final AnimationController _controller = AnimationController(vsync: this, duration: _period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DsMotion.reduced(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
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
    final size = widget.size;
    final core = size * 0.56;
    const slots = [Alignment(-0.92, -0.5), Alignment(0.95, -0.2), Alignment(0.55, 0.9)];
    return ExcludeSemantics(
      child: SizedBox(
        width: size * 1.5,
        height: size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final pulse = (1 - math.cos(2 * math.pi * t)) / 2;
            Widget ring(double phase) {
              final p = (t + phase) % 1;
              return Opacity(
                opacity: (1 - p) * 0.35,
                child: Transform.scale(
                  scale: 0.7 + p * 0.7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.actionPrimary, width: 2),
                    ),
                    child: SizedBox.square(dimension: size * 0.8),
                  ),
                ),
              );
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                if (_controller.isAnimating) ...[ring(0), ring(0.5)],
                Transform.scale(
                  scale: 1 + 0.06 * pulse,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [c.actionPrimary.withValues(alpha: 0.22), c.actionPrimary.withValues(alpha: 0)],
                      ),
                    ),
                    child: SizedBox.square(dimension: size * 0.95),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -4 * math.sin(2 * math.pi * t)),
                  child: SvgPicture.asset(widget.asset, width: core, height: core),
                ),
                for (final (i, asset) in widget.orbit.take(slots.length).indexed)
                  Align(
                    alignment: slots[i],
                    child: Transform.translate(
                      offset: Offset(0, 5 * math.sin(2 * math.pi * (t + i * 0.33))),
                      child: Transform.rotate(
                        angle: 0.12 * math.sin(2 * math.pi * (t + i * 0.33)),
                        child: SvgPicture.asset(asset, width: size * 0.26, height: size * 0.26),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
