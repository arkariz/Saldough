import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Nominal ringkas untuk sumbu grafik: "8 jt", "850 rb", "0". Pembulatan
/// hanya untuk tampilan.
String axisLabel(int sen) {
  final units = (sen.abs() + 50) ~/ 100;
  final sign = sen < 0 ? '−' : '';
  if (units >= 1000000) {
    final tenths = (units + 50000) ~/ 100000;
    final value = tenths % 10 == 0 ? '${tenths ~/ 10}' : '${tenths ~/ 10}${MoneySeparators.decimal}${tenths % 10}';
    return '$sign${t.plan.compactMillion(value: value)}';
  }
  if (units >= 1000) return '$sign${t.plan.compactThousand(value: (units + 500) ~/ 1000)}';
  return '$sign$units';
}

/// Grafik **saldo per hari** (acuan "Tren Aliran Kas"): kurva halus berwarna
/// aksi dengan gradasi di bawahnya, panduan mendatar garis rambut dengan label
/// sumbu, titik simpul di terendah, titik fokus dengan garis tegak tipis,
/// dan tooltip di atasnya. Geser atau ketuk memindahkan fokus; kurva
/// tergambar dari kiri ke kanan sekali saat pertama tampil. Bagian di bawah
/// nol berwarna merah.
class PlanBalanceChart extends StatefulWidget {
  /// Membuat [PlanBalanceChart].
  const PlanBalanceChart({required this.days, required this.low, required this.isFuture, this.height = 200, super.key});

  /// Saldo per hari, minimal dua.
  final List<ProjectedDay> days;

  /// Hari saldo terendah, atau `null`.
  final ProjectedDay? low;

  /// Bulan depan: label awal bukan "hari ini".
  final bool isFuture;

  /// Tinggi area gambar.
  final double height;

  @override
  State<PlanBalanceChart> createState() => _PlanBalanceChartState();
}

class _PlanBalanceChartState extends State<PlanBalanceChart> {
  int? _selected;

  int get _active {
    final chosen = _selected;
    if (chosen != null && chosen < widget.days.length) return chosen;
    final low = widget.low;
    final index = low == null ? -1 : widget.days.indexOf(low);
    return index >= 0 ? index : widget.days.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final reduced = DsMotion.reduced(context);
    final days = widget.days;
    final balances = [for (final d in days) d.balance];
    final geometry = _ChartGeometry(balances);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final size = Size(width, widget.height);
        void select(double dx) {
          final plotWidth = width - _ChartGeometry.left;
          final fraction = ((dx - _ChartGeometry.left) / plotWidth).clamp(0.0, 1.0);
          setState(() => _selected = (fraction * (days.length - 1)).round());
        }

        final active = _active;
        final point = geometry.point(size, active);
        final day = days[active];
        final isLow = widget.low != null && day == widget.low;
        final tooltipWidth = math.min<double>(150, width * 0.5);
        final tooltipLeft = (point.dx - tooltipWidth / 2).clamp(_ChartGeometry.left - 4, width - tooltipWidth);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: reduced ? 1 : 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          curve: DsMotion.easeOutExpo,
          builder: (context, progress, _) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => select(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => select(d.localPosition.dx),
            onTapDown: (d) => select(d.localPosition.dx),
            child: SizedBox(
              width: width,
              height: widget.height + 34,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 34,
                    left: 0,
                    right: 0,
                    child: CustomPaint(
                      size: size,
                      painter: _ChartPainter(
                        geometry: geometry,
                        progress: progress,
                        activeIndex: active,
                        lowIndex: widget.low == null ? null : days.indexOf(widget.low!),
                        line: c.actionPrimary,
                        negative: c.error,
                        guide: c.outlineSubtle,
                        axis: c.textMuted,
                        ring: c.surfaceCard,
                        marker: c.textPrimary,
                        labelStyle: ds.typography.labelMd.copyWith(fontSize: 10, color: c.textMuted),
                        activeLabelStyle: ds.typography.labelMd.copyWith(
                          fontSize: 10,
                          color: c.actionPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        xLabels: [
                          for (final i in _xIndexes(days.length))
                            (
                              i,
                              i == 0 && !widget.isFuture
                                  ? t.plan.todayLabel
                                  : CycleMonthFormatter.formatDayMonth(days[i].date),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Tooltip di atas titik fokus.
                  Positioned(
                    left: tooltipLeft,
                    top: 0,
                    width: tooltipWidth,
                    child: AnimatedOpacity(
                      duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
                      opacity: progress >= 0.95 ? 1 : 0,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.surfaceContainerHigh.withValues(alpha: 0.96),
                            borderRadius: DsRadius.mdAll,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isLow
                                      ? t.plan.lowestOn(date: CycleMonthFormatter.formatDayMonth(day.date))
                                      : CycleMonthFormatter.formatDayMonth(day.date),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ds.typography.labelMd.copyWith(fontSize: 10, color: c.textSecondary),
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    '≈${AppMoneyFormatter.formatApprox(day.balance)}',
                                    style: ds.typography.amountSm.copyWith(
                                      color: day.balance < 0 ? c.error : c.actionPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Indeks hari untuk label sumbu x: awal, seperempat, tengah, tiga
  /// perempat, dan akhir (tanpa duplikat).
  static List<int> _xIndexes(int count) {
    if (count <= 1) return const [0];
    final last = count - 1;
    return {0, (last * 0.25).round(), (last * 0.5).round(), (last * 0.75).round(), last}.toList()..sort();
  }
}

/// Skala dan titik grafik: rentang nilai dibulatkan ke langkah "enak" supaya
/// label sumbu bulat.
class _ChartGeometry {
  _ChartGeometry(this.balances) {
    final lo = [...balances, 0].reduce(math.min).toDouble();
    final hi = [...balances, 0].reduce(math.max).toDouble();
    final raw = (hi - lo).abs() < 1 ? 1.0 : (hi - lo) / 3;
    step = _niceStep(raw);
    minValue = (lo / step).floorToDouble() * step;
    maxValue = (hi / step).ceilToDouble() * step;
    if (maxValue - minValue < step) maxValue = minValue + step;
  }

  /// Ruang label sumbu y di kiri dan label sumbu x di bawah.
  static const double left = 34;
  static const double bottom = 22;
  static const double top = 8;

  final List<int> balances;
  late final double step;
  late final double minValue;
  late final double maxValue;

  /// Langkah 1–2–5 × 10^n (satuan sen).
  static double _niceStep(double raw) {
    final exponent = (math.log(raw) / math.ln10).floor();
    final base = math.pow(10, exponent).toDouble();
    final fraction = raw / base;
    final nice = fraction <= 1 ? 1 : (fraction <= 2 ? 2 : (fraction <= 5 ? 5 : 10));
    return nice * base;
  }

  List<double> get ticks => [for (var v = minValue; v <= maxValue + step / 2; v += step) v];

  double plotWidth(Size size) => size.width - left;
  double plotHeight(Size size) => size.height - bottom - top;

  double x(Size size, int i) => left + (balances.length == 1 ? 0 : i / (balances.length - 1)) * plotWidth(size);
  double y(Size size, num value) => top + (1 - (value - minValue) / (maxValue - minValue)) * plotHeight(size);

  Offset point(Size size, int i) => Offset(x(size, i), y(size, balances[i]) + 34);
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.geometry,
    required this.progress,
    required this.activeIndex,
    required this.lowIndex,
    required this.line,
    required this.negative,
    required this.guide,
    required this.axis,
    required this.ring,
    required this.marker,
    required this.labelStyle,
    required this.activeLabelStyle,
    required this.xLabels,
  });

  final _ChartGeometry geometry;
  final double progress;
  final int activeIndex;
  final int? lowIndex;
  final Color line;
  final Color negative;
  final Color guide;
  final Color axis;
  final Color ring;
  final Color marker;
  final TextStyle labelStyle;
  final TextStyle activeLabelStyle;
  final List<(int, String)> xLabels;

  void _text(Canvas canvas, String text, TextStyle style, Offset anchor, {TextAlign align = TextAlign.center}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.right || TextAlign.end => anchor.dx - painter.width,
      TextAlign.left || TextAlign.start => anchor.dx,
      _ => anchor.dx - painter.width / 2,
    };
    painter.paint(canvas, Offset(dx, anchor.dy - painter.height / 2));
  }

  /// Kurva monoton (Fritsch–Carlson) lewat titik harian: halus tanpa
  /// melampaui nilai antar titik.
  Path _curve(Size size) {
    final n = geometry.balances.length;
    final xs = [for (var i = 0; i < n; i++) geometry.x(size, i)];
    final ys = [for (var i = 0; i < n; i++) geometry.y(size, geometry.balances[i])];
    final path = Path()..moveTo(xs[0], ys[0]);
    if (n == 2) return path..lineTo(xs[1], ys[1]);
    final d = List<double>.filled(n - 1, 0);
    for (var i = 0; i < n - 1; i++) {
      d[i] = (ys[i + 1] - ys[i]) / (xs[i + 1] - xs[i]);
    }
    final m = List<double>.filled(n, 0)
      ..[0] = d[0]
      ..[n - 1] = d[n - 2];
    for (var i = 1; i < n - 1; i++) {
      m[i] = d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2;
    }
    for (var i = 0; i < n - 1; i++) {
      if (d[i] == 0) {
        m[i] = 0;
        m[i + 1] = 0;
        continue;
      }
      final a = m[i] / d[i];
      final b = m[i + 1] / d[i];
      final s = a * a + b * b;
      if (s > 9) {
        final tau = 3 / math.sqrt(s);
        m[i] = tau * a * d[i];
        m[i + 1] = tau * b * d[i];
      }
    }
    for (var i = 0; i < n - 1; i++) {
      final dx = (xs[i + 1] - xs[i]) / 3;
      path.cubicTo(xs[i] + dx, ys[i] + m[i] * dx, xs[i + 1] - dx, ys[i + 1] - m[i + 1] * dx, xs[i + 1], ys[i + 1]);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (geometry.balances.length < 2) return;
    const plotLeft = _ChartGeometry.left;
    final plotRight = size.width;
    final baseline = size.height - _ChartGeometry.bottom;

    // Panduan mendatar garis rambut dan label sumbu y.
    final guidePaint = Paint()
      ..color = guide
      ..strokeWidth = 1;
    for (final tick in geometry.ticks) {
      final y = geometry.y(size, tick);
      canvas.drawLine(Offset(plotLeft, y), Offset(plotRight, y), guidePaint);
      _text(canvas, axisLabel(tick.round()), labelStyle, Offset(plotLeft - 6, y), align: TextAlign.right);
    }

    final curve = _curve(size);
    final zeroY = geometry.y(size, 0);
    final area = Path.from(curve)
      ..lineTo(geometry.x(size, geometry.balances.length - 1), baseline)
      ..lineTo(geometry.x(size, 0), baseline)
      ..close();

    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(plotLeft - 2, 0, plotLeft + (plotRight - plotLeft) * progress, size.height))
      // Gradasi di bawah kurva: aksi memudar ke transparan.
      ..drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [line.withValues(alpha: 0.28), line.withValues(alpha: 0)],
          ).createShader(Rect.fromLTRB(plotLeft, _ChartGeometry.top, plotRight, baseline)),
      );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Bagian di atas nol berwarna aksi, di bawahnya merah.
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(0, 0, size.width, math.max(zeroY, 0) + 0.5))
      ..drawPath(curve, stroke..color = line)
      ..restore();
    if (geometry.minValue < 0) {
      canvas
        ..drawLine(Offset(plotLeft, zeroY), Offset(plotRight, zeroY), Paint()..color = axis.withValues(alpha: 0.6))
        ..save()
        ..clipRect(Rect.fromLTRB(0, zeroY - 0.5, size.width, size.height))
        ..drawPath(curve, stroke..color = negative)
        ..restore();
    }
    canvas.restore();

    // Label sumbu x; yang aktif ditebalkan.
    final activeX = geometry.x(size, activeIndex);
    for (final (i, label) in xLabels) {
      final x = geometry.x(size, i);
      final near = (x - activeX).abs() < 24;
      _text(
        canvas,
        label,
        near ? activeLabelStyle : labelStyle,
        Offset(x.clamp(plotLeft + 14, plotRight - 18), size.height - 8),
      );
    }

    if (progress < 0.95) return;

    void node(int i, {required double radius, required Color stroke, required Color fill}) {
      final center = Offset(geometry.x(size, i), geometry.y(size, geometry.balances[i]));
      canvas
        ..drawCircle(center, radius + 2, Paint()..color = ring)
        ..drawCircle(center, radius, Paint()..color = fill)
        ..drawCircle(
          center,
          radius,
          Paint()
            ..color = stroke
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
    }

    // Simpul titik terendah.
    if (lowIndex case final i? when i >= 0 && i < geometry.balances.length && i != activeIndex) {
      node(i, radius: 3.5, stroke: geometry.balances[i] < 0 ? negative : marker, fill: ring);
    }
    // Fokus: garis tegak tipis dan titik berisi.
    canvas.drawLine(
      Offset(activeX, _ChartGeometry.top),
      Offset(activeX, baseline),
      Paint()
        ..color = line.withValues(alpha: 0.45)
        ..strokeWidth = 1.5,
    );
    final activeBalance = geometry.balances[activeIndex];
    node(
      activeIndex,
      radius: 5,
      stroke: activeBalance < 0 ? negative : line,
      fill: activeBalance < 0 ? negative : line,
    );
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.progress != progress ||
      old.activeIndex != activeIndex ||
      old.lowIndex != lowIndex ||
      old.geometry.balances != geometry.balances ||
      old.line != line ||
      old.ring != ring;
}
