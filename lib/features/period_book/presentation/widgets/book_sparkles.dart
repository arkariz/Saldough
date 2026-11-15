import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';

/// Kilau emas yang berkedip di sekeliling buku (rupa D5): empat `sparkle.svg`
/// berpasangan skala dan putar dengan fase berbeda. Satu `Ticker`. Tidak
/// menggambar apa pun saat gerak dikurangi.
class BookSparkles extends StatefulWidget {
  /// Membuat [BookSparkles].
  const BookSparkles({super.key});

  @override
  State<BookSparkles> createState() => _BookSparklesState();
}

class _BookSparklesState extends State<BookSparkles> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

  // Posisi relatif (0-1), ukuran, fase.
  static const _spots = [
    (0.06, 0.18, 18.0, 0.0),
    (0.9, 0.12, 14.0, 0.3),
    (0.04, 0.74, 12.0, 0.55),
    (0.93, 0.66, 20.0, 0.8),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DsMotion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (DsMotion.reduced(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) => AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Stack(
            children: [
              for (final (x, y, size, phase) in _spots)
                Positioned(
                  left: box.maxWidth * x - size / 2,
                  top: box.maxHeight * y - size / 2,
                  child: Builder(
                    builder: (context) {
                      final k = (_c.value + phase) % 1;
                      final s = math.sin(k * math.pi);
                      return Opacity(
                        opacity: s.clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: k * math.pi / 2,
                          child: Transform.scale(scale: 0.3 + 0.9 * s, child: SvgPicture.asset(ClayIcons.sparkle, width: size, height: size)),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
