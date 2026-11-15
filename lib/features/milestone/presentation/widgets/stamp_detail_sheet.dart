import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/full_screen_sheet.dart';
import 'package:saldough/features/milestone/presentation/widgets/stamp_visuals.dart';

/// Lembar detail stempel (rupa buku-stempel §4.5 dan §9, gaya Kaya): segel besar
/// dengan sinar emas berputar di belakangnya yang **miring 3D mengikuti jari**
/// (±20° Y, ±17° X). Stempel yang belum dilihat memicu satu ledakan konfeti
/// (≤36 partikel) dan getar layar lewat [onCelebrate]. **Tidak ada "Cap lagi"**:
/// stempel tidak boleh terasa bisa diulang (G-3).
///
/// Semua gerak mati saat gerak dikurangi: sinar diam, segel tidak miring, tanpa
/// konfeti.
Future<void> showStampDetailSheet(
  BuildContext context, {
  required String id,
  required bool earned,
  required bool isNew,
  required String body,
  VoidCallback? onCelebrate,
}) {
  return showAppSheet<void>(
    context,
    isScrollControlled: true,
    builder: (context) => _StampDetail(id: id, earned: earned, isNew: isNew, body: body, onCelebrate: onCelebrate),
  );
}

class _StampDetail extends StatefulWidget {
  const _StampDetail({
    required this.id,
    required this.earned,
    required this.isNew,
    required this.body,
    required this.onCelebrate,
  });

  final String id;
  final bool earned;
  final bool isNew;
  final String body;
  final VoidCallback? onCelebrate;

  @override
  State<_StampDetail> createState() => _StampDetailState();
}

class _StampDetailState extends State<_StampDetail> with SingleTickerProviderStateMixin {
  static const double _maxY = 20 * math.pi / 180;
  static const double _maxX = 17 * math.pi / 180;

  late final AnimationController _rays = AnimationController(vsync: this, duration: const Duration(seconds: 14));
  final GlobalKey _sealKey = GlobalKey();
  Offset _tilt = Offset.zero; // x = rotasi sumbu Y, y = rotasi sumbu X
  bool _dragging = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DsMotion.reduced(context)) {
      _rays.stop();
    } else if (!_rays.isAnimating && widget.earned) {
      _rays.repeat();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.earned && widget.isNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final box = _sealKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          DsCelebration.burst(context, origin: box.localToGlobal(box.size.center(Offset.zero)), count: 36);
        }
        widget.onCelebrate?.call();
      });
    }
  }

  @override
  void dispose() {
    _rays.dispose();
    super.dispose();
  }

  void _track(Offset local, Size size) {
    if (DsMotion.reduced(context)) return;
    final dx = ((local.dx / size.width) - 0.5) * 2;
    final dy = ((local.dy / size.height) - 0.5) * 2;
    setState(() {
      _dragging = true;
      _tilt = Offset((dx * _maxY).clamp(-_maxY, _maxY), (-dy * _maxX).clamp(-_maxX, _maxX));
    });
  }

  void _release() => setState(() {
    _dragging = false;
    _tilt = Offset.zero;
  });

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final name = stampName(widget.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 230,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.earned)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _rays,
                      builder: (context, _) => Transform.rotate(
                        angle: _rays.value * 2 * math.pi,
                        child: CustomPaint(
                          size: const Size.square(230),
                          painter: _RaysPainter(ds.colors.stampGoldDeep),
                        ),
                      ),
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, box) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: (d) => _track(d.localPosition, box.biggest),
                    onPanUpdate: (d) => _track(d.localPosition, box.biggest),
                    onPanEnd: (_) => _release(),
                    onPanCancel: _release,
                    child: SizedBox(
                      width: 150,
                      height: 130,
                      child: Center(
                        child: TweenAnimationBuilder<Offset>(
                          tween: Tween(begin: Offset.zero, end: _tilt),
                          duration: _dragging ? const Duration(milliseconds: 60) : const Duration(milliseconds: 250),
                          builder: (context, tilt, child) => Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0016)
                              ..rotateX(tilt.dy)
                              ..rotateY(tilt.dx),
                            child: child,
                          ),
                          child: DsStampSeal(
                            key: _sealKey,
                            asset: stampAsset(widget.id),
                            semanticLabel: name,
                            earned: widget.earned,
                            isNew: widget.earned && widget.isNew,
                            size: DsStampSealSize.lg,
                            rotation: stampRotation(widget.id),
                            shine: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(name, style: ds.typography.headlineSm, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 8),
          Text(
            widget.body,
            textAlign: TextAlign.center,
            style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary),
          ),
          const SizedBox(height: 16),
          DsButton(label: t.stamps.detail.close, onPressed: () => Navigator.of(context).pop(), expand: true),
        ],
      ),
    );
  }
}

/// Sinar emas: baji bergantian terisi dan kosong tiap 10°, memudar ke tepi
/// (acuan `repeating-conic-gradient` + topeng radial).
class _RaysPainter extends CustomPainter {
  const _RaysPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
        stops: const [0.25, 0.7],
      ).createShader(rect);
    const wedge = 8 * math.pi / 180;
    const step = 20 * math.pi / 180;
    for (var a = 0.0; a < 2 * math.pi; a += step) {
      canvas.drawArc(rect, a, wedge, true, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color;
}
