import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/motion/motion.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/onboarding/presentation/widgets/onboarding_scene.dart';

/// Satu layar onboarding: adegan bergerak di atas, panel judul dan isi di
/// bawah. Adegan berparalaks setengah kecepatan geser (ADR-021 §3.7).
class OnboardingSlide extends StatelessWidget {
  /// Membuat [OnboardingSlide].
  const OnboardingSlide({required this.index, required this.active, required this.controller, super.key});

  /// Urutan layar, 0..[onboardingSlideCount] - 1.
  final int index;

  /// True saat layar ini yang tampil — hanya layar aktif yang bergerak.
  final bool active;

  /// Controller `PageView`, sumber posisi paralaks.
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    final (title, body) = onboardingText(index);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: LayoutBuilder(
              builder: (context, constraints) => AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  final page = controller.hasClients && controller.position.haveDimensions
                      ? controller.page ?? index.toDouble()
                      : index.toDouble();
                  // Paralaks: adegan tertinggal setengah dari geseran halaman.
                  final dx = snapToPixelGrid((page - index) * constraints.maxWidth * 0.5);
                  return Transform.translate(offset: Offset(dx, 0), child: child);
                },
                child: ExcludeSemantics(
                  child: OnboardingScene(index: index, active: active),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            flex: 2,
            child: SingleChildScrollView(
              child: PixelPop(
                play: active,
                delay: const Duration(milliseconds: 120),
                alignment: Alignment.bottomCenter,
                child: AppHardCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(body, style: Theme.of(context).textTheme.bodyMedium),
                    ],
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

/// Indikator halaman berupa blok piksel; blok aktif memanjang bertangga.
class OnboardingPageIndicator extends StatelessWidget {
  /// Membuat [OnboardingPageIndicator].
  const OnboardingPageIndicator({required this.count, required this.current, super.key});

  /// Jumlah halaman.
  final int count;

  /// Halaman aktif, dari 0.
  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final duration = MotionPolicy.duration(context, const Duration(milliseconds: 240));
    return Semantics(
      label: t.onboarding.pageIndicatorLabel(current: current + 1, total: count),
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: duration,
                curve: const SteppedCurve(4),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == current ? 28 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: i == current ? colors.accent : colors.cardBackground,
                  border: Border.all(color: colors.textPrimary, width: AppBorder.pixelThick),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Latar onboarding: warna yang bergeser lembut per halaman dan kisi titik
/// piksel yang mengalir pelan secara diagonal.
class OnboardingBackdrop extends StatefulWidget {
  /// Membuat [OnboardingBackdrop].
  const OnboardingBackdrop({required this.controller, super.key});

  /// Controller `PageView`, sumber warna per halaman.
  final PageController controller;

  @override
  State<OnboardingBackdrop> createState() => _OnboardingBackdropState();
}

class _OnboardingBackdropState extends State<OnboardingBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(vsync: this, duration: const Duration(seconds: 12));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionPolicy.reduced(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      unawaited(_drift.repeat());
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tones = [colors.background, colors.surfaceMid, colors.surfaceLow, colors.surfaceMid, colors.surfaceHigh];
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.controller, _drift]),
        builder: (context, _) {
          final controller = widget.controller;
          final page = controller.hasClients && controller.position.haveDimensions ? controller.page ?? 0 : 0.0;
          final lower = page.floor().clamp(0, tones.length - 1);
          final upper = (lower + 1).clamp(0, tones.length - 1);
          final tone = Color.lerp(tones[lower], tones[upper], page - page.floor())!;
          return CustomPaint(
            painter: _DotGridPainter(
              background: tone,
              dot: colors.textPrimary.withValues(alpha: 0.07),
              shift: snapToPixelGrid(_drift.value * _DotGridPainter.spacing),
            ),
          );
        },
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({required this.background, required this.dot, required this.shift});

  static const spacing = 24.0;

  final Color background;
  final Color dot;
  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()..color = dot;
    for (var y = -spacing + shift; y < size.height; y += spacing) {
      for (var x = -spacing + shift; x < size.width; x += spacing) {
        canvas.drawRect(Rect.fromLTWH(x, y, 2, 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) =>
      oldDelegate.background != background || oldDelegate.shift != shift || oldDelegate.dot != dot;
}
