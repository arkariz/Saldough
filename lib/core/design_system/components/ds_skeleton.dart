import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Blok tempat-penampung untuk pemuatan pertama: berdenyut pelan antara
/// `surfaceSunken` dan `surfaceContainer`; diam bila animasi dikurangi.
class DsSkeleton extends StatefulWidget {
  /// Membuat blok setinggi [height] dan selebar [width] (`null` = mengisi).
  const DsSkeleton({required this.height, this.width, this.radius = DsRadius.smAll, super.key});

  /// Blok bulat setinggi dan selebar [size].
  const DsSkeleton.circle({required double size, super.key})
    : height = size,
      width = size,
      radius = const BorderRadius.all(Radius.circular(999));

  /// Tinggi blok.
  final double height;

  /// Lebar blok; `null` mengisi lebar yang tersedia.
  final double? width;

  /// Sudut blok.
  final BorderRadius radius;

  @override
  State<DsSkeleton> createState() => _DsSkeletonState();
}

class _DsSkeletonState extends State<DsSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
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
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(c.surfaceSunken, c.surfaceContainer, Curves.easeInOut.transform(_controller.value)),
            borderRadius: widget.radius,
          ),
        ),
      ),
    );
  }
}
