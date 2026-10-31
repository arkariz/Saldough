import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/motion/motion.dart';
import 'package:saldough/core/presentation/spotlight/spotlight_controller.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';

/// Lapisan tur: latar gelap berlubang di sekitar target, bingkai aksen yang
/// berkedip, dan gelembung kartu v2 berisi langkahnya (ADR-021 §3.3,
/// §3.7). Menyerap semua ketukan, jadi target tidak menjalankan aksinya
/// selama tur.
class SpotlightOverlay extends StatefulWidget {
  /// Membuat [SpotlightOverlay] untuk [controller] yang sedang aktif.
  const SpotlightOverlay({required this.controller, super.key});

  /// Controller tur.
  final SpotlightController controller;

  @override
  State<SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<SpotlightOverlay> with TickerProviderStateMixin {
  /// Perpindahan lubang dari target lama ke target baru.
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  /// Kedip dua frame bingkai aksen.
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// Latar gelap memudar masuk.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  /// Tanda centang penutup tur.
  late final AnimationController _done = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  Rect? _target;
  Rect? _from;
  int _shownIndex = -1;
  bool _completing = false;

  static const Curve _moveCurve = Curves.easeInOut;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStepChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MotionPolicy.reduced(context);
    if (reduced) {
      _intro.value = 1;
      _blink.stop();
    } else {
      if (_intro.value == 0) _intro.forward();
      if (!_blink.isAnimating) _blink.repeat();
    }
    if (_shownIndex < 0) _onStepChanged();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStepChanged);
    _move.dispose();
    _blink.dispose();
    _intro.dispose();
    _done.dispose();
    super.dispose();
  }

  Rect? _measureTarget() {
    final step = widget.controller.currentStep;
    if (step == null) return null;
    final target = widget.controller.targetContext(step.key)?.findRenderObject() as RenderBox?;
    final overlay = context.findRenderObject() as RenderBox?;
    if (target == null || overlay == null || !overlay.hasSize) return null;
    final topLeft = overlay.globalToLocal(target.localToGlobal(Offset.zero));
    return topLeft & target.size;
  }

  /// Mengukur ulang target sesudah frame yang digambar lapisan ini — target
  /// bisa bergeser karena gulir `ensureVisible` atau animasi layar di
  /// bawahnya. Sengaja bukan `Ticker` terus-menerus: itu menjadwalkan frame
  /// tanpa henti (boros baterai, dan uji tidak pernah tenang).
  void _remeasure() {
    if (!mounted) return;
    final rect = _measureTarget();
    if (rect != null && rect != _target) setState(() => _target = rect);
  }

  void _onStepChanged() {
    final controller = widget.controller;
    if (!controller.isActive || controller.index == _shownIndex) return;
    _shownIndex = controller.index;
    final step = controller.currentStep!;
    final reduced = MotionPolicy.reduced(context);
    final targetContext = controller.targetContext(step.key);
    if (targetContext != null) {
      // Sesudah frame: dengan gerak dikurangi gulirnya langsung (durasi
      // nol), dan menggulir saat membangun membuat AppBar halaman
      // ditandai kotor di tengah pembangunan.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !targetContext.mounted) return;
        unawaited(
          Scrollable.ensureVisible(
            targetContext,
            alignment: 0.3,
            duration: reduced ? Duration.zero : const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          ).then((_) => _remeasure()),
        );
      });
    }
    // Lubang pertama menyempit dari lingkaran besar ("iris"); berikutnya
    // berpindah dari target sebelumnya.
    final current = _displayRect;
    final next = _measureTarget();
    _from = current ?? next?.inflate(160);
    _target = next ?? _target;
    if (reduced) {
      _move.value = 1;
    } else {
      _move.forward(from: 0);
    }
    if (mounted) setState(() {});
  }

  Rect? get _displayRect {
    final target = _target;
    if (target == null) return null;
    final from = _from;
    if (from == null) return target;
    return Rect.lerp(from, target, _moveCurve.transform(_move.value));
  }

  Future<void> _onNext() async {
    final controller = widget.controller;
    if (!controller.isLastStep) return controller.next();
    if (MotionPolicy.reduced(context)) return controller.finish();
    setState(() => _completing = true);
    await _done.forward();
    await controller.finish();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final step = controller.currentStep;
    if (step == null) return const SizedBox.shrink();
    return Builder(
      builder: (context) {
        final colors = context.ds.colors;
        return FadeTransition(
          opacity: _intro,
          child: AnimatedBuilder(
            animation: Listenable.merge([_move, _blink]),
            builder: (context, _) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
              final hole = _displayRect;
              final bright = !_blink.isAnimating || _blink.value < 0.5;
              final size = MediaQuery.sizeOf(context);
              // Papan ketik (mis. bidang nominal CATAT yang langsung fokus)
              // mengurangi ruang bawah; gelembung tidak boleh tertutup.
              final keyboard = MediaQuery.viewInsetsOf(context).bottom;
              final safe = MediaQuery.paddingOf(context);
              final bottomLimit = size.height - math.max(keyboard, safe.bottom);
              final below = hole == null || (bottomLimit - hole.bottom) >= hole.top;
              return Material(
                type: MaterialType.transparency,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                        child: CustomPaint(
                          painter: _ScrimPainter(
                            hole: hole,
                            below: below,
                            scrim: colors.scrim.withValues(alpha: 0.74),
                            border: colors.actionPrimary.withValues(alpha: bright ? 1 : 0.35),
                            tail: colors.surfaceCard,
                            edge: colors.outlineSubtle,
                          ),
                        ),
                      ),
                    ),
                    CustomSingleChildLayout(
                      delegate: _BubbleLayout(
                        hole: hole,
                        below: below,
                        padding: safe.copyWith(bottom: math.max(keyboard, safe.bottom)),
                      ),
                      child: _completing
                          ? _DoneBadge(animation: _done)
                          : _Bubble(controller: controller, onNext: _onNext),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Gelembung langkah: avatar maskot, penanda langkah, judul, isi, aksi.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.controller, required this.onNext});

  final SpotlightController controller;
  final Future<void> Function() onNext;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final step = controller.currentStep!;
    final current = controller.index + 1;
    final total = controller.steps.length;
    return AppFadeIn(
      key: ValueKey(controller.index),
      child: Semantics(
        container: true,
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: t.tour.stepSemantics(current: current, total: total, title: step.title, body: step.body),
        child: Container(
          padding: const EdgeInsets.all(DsSpacing.md),
          decoration: BoxDecoration(
            color: c.surfaceCard,
            borderRadius: DsRadius.lgAll,
            border: Border.all(color: c.outlineSubtle),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _MascotAvatar(),
                  const SizedBox(width: DsSpacing.stack),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(child: _StepBlocks(current: current, total: total)),
                        const SizedBox(height: 6),
                        ExcludeSemantics(child: Text(step.title, style: ds.typography.titleMd)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.sm),
              Flexible(
                child: SingleChildScrollView(
                  child: ExcludeSemantics(
                    child: Text(step.body, style: ds.typography.bodyMd.copyWith(color: c.textSecondary)),
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.stack),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: DsSpacing.sm,
                runSpacing: DsSpacing.xs,
                children: [
                  DsButton.ghost(label: t.tour.skipAction, onPressed: controller.finish),
                  DsButton(
                    label: controller.isLastStep ? t.tour.doneAction : t.tour.nextAction,
                    onPressed: onNext,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Maskot tanuki clay yang melayang pelan di sudut gelembung.
class _MascotAvatar extends StatelessWidget {
  const _MascotAvatar();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DsIdleMotion(
        kind: DsIdleKind.float,
        child: DsIconTile.child(
          child: SvgPicture.asset(ClayIcons.mascot, width: 40, height: 40),
        ),
      ),
    );
  }
}

/// Penanda langkah: batang kecil terisi sampai langkah aktif, plus "n/m".
class _StepBlocks extends StatelessWidget {
  const _StepBlocks({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Row(
      children: [
        for (var i = 1; i <= total; i++)
          Container(
            width: 14,
            height: 6,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: i <= current ? c.actionPrimary : c.surfaceContainerHigh,
              borderRadius: DsRadius.fullAll,
            ),
          ),
        const SizedBox(width: DsSpacing.xs),
        Text(
          t.tour.stepCounter(current: current, total: total),
          style: ds.typography.labelSm.copyWith(color: c.textMuted),
        ),
      ],
    );
  }
}

/// Centang besar yang muncul sebelum tur menutup.
class _DoneBadge extends StatelessWidget {
  const _DoneBadge({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return Center(
      child: AppFadeIn(
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.surfaceCard, shape: BoxShape.circle),
          child: Icon(Icons.check_circle, size: 44, color: c.actionPrimary),
        ),
      ),
    );
  }
}

/// Menempatkan gelembung di bawah target kalau ruang bawah lebih lapang,
/// selain itu di atasnya; selalu di dalam area aman layar.
class _BubbleLayout extends SingleChildLayoutDelegate {
  _BubbleLayout({required this.hole, required this.below, required this.padding});

  final Rect? hole;
  final bool below;
  final EdgeInsets padding;

  static const _margin = 16.0;
  static const _gap = 20.0;
  static const _maxWidth = 380.0;

  double _top(Size size) => padding.top + _margin;
  double _bottom(Size size) => size.height - padding.bottom - _margin;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final size = constraints.biggest;
    final width = math.min(size.width - _margin * 2, _maxWidth);
    final hole = this.hole;
    final available = hole == null
        ? _bottom(size) - _top(size)
        : below
        ? _bottom(size) - (hole.bottom + _gap)
        : (hole.top - _gap) - _top(size);
    return BoxConstraints(maxWidth: width, minWidth: width, maxHeight: math.max(available, 120));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final hole = this.hole;
    final centerX = hole?.center.dx ?? size.width / 2;
    final x = (centerX - childSize.width / 2).clamp(_margin, size.width - _margin - childSize.width);
    final double y;
    if (hole == null) {
      y = (size.height - childSize.height) / 2;
    } else if (below) {
      y = hole.bottom + _gap;
    } else {
      y = hole.top - _gap - childSize.height;
    }
    final maxY = math.max(_top(size), _bottom(size) - childSize.height);
    return Offset(x, y.clamp(_top(size), maxY));
  }

  @override
  bool shouldRelayout(_BubbleLayout oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.below != below || oldDelegate.padding != padding;
}

/// Latar gelap berlubang, bingkai aksen, dan ekor bertangga ke gelembung.
class _ScrimPainter extends CustomPainter {
  _ScrimPainter({
    required this.hole,
    required this.below,
    required this.scrim,
    required this.border,
    required this.tail,
    required this.edge,
  });

  final Rect? hole;
  final bool below;
  final Color scrim;
  final Color border;
  final Color tail;
  final Color edge;

  static const _inflate = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    final hole = this.hole;
    if (hole == null) {
      canvas.drawRect(screen, Paint()..color = scrim);
      return;
    }
    final rrect = RRect.fromRectAndRadius(hole.inflate(_inflate), const Radius.circular(DsRadius.lg));
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(screen)
      ..addRRect(rrect);
    canvas
      ..drawPath(path, Paint()..color = scrim)
      ..drawRRect(
        rrect,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

    // Ekor segitiga dari bingkai ke arah gelembung.
    final x = hole.center.dx.clamp(28, size.width - 28).toDouble();
    final tip = below ? rrect.bottom + 4 : rrect.top - 4;
    final base = below ? tip + 10 : tip - 10;
    final caret = Path()
      ..moveTo(x, tip)
      ..lineTo(x - 9, base)
      ..lineTo(x + 9, base)
      ..close();
    canvas
      ..drawPath(caret, Paint()..color = tail)
      ..drawPath(
        caret,
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(_ScrimPainter oldDelegate) =>
      oldDelegate.hole != hole ||
      oldDelegate.border != border ||
      oldDelegate.below != below ||
      oldDelegate.scrim != scrim ||
      oldDelegate.tail != tail;
}
