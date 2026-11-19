// Kanvas digambar perintah demi perintah; kaskade tidak menolong keterbacaan.
// ignore_for_file: cascade_invocations

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/wallet/presentation/bloc/wealth_history_state.dart';

/// Grafik Total aset per periode (B-100): kurva halus berwarna aksi dengan
/// gradasi di bawahnya, satu titik per periode, titik terpilih dengan halo dan
/// garis tegak tipis. Titik yang nilai investasinya kedaluwarsa digambar
/// berongga. Ketuk atau geser memilih periode; kurva tergambar dari kiri ke
/// kanan sekali saat pertama tampil.
///
/// Sumbu tidak diberi angka supaya "Sembunyikan nominal" tidak bocor lewat
/// grafik; nominal periode terpilih ada di kartu di atasnya.
class WealthHistoryChart extends StatefulWidget {
  /// Membuat [WealthHistoryChart].
  const WealthHistoryChart({required this.points, required this.selected, required this.onSelected, this.height = 180, super.key});

  /// Titik per periode, terlama dulu (minimal dua).
  final List<WealthPeriodPoint> points;

  /// Indeks titik terpilih.
  final int selected;

  /// Dipanggil saat pengguna memilih titik lain.
  final ValueChanged<int> onSelected;

  /// Tinggi area gambar.
  final double height;

  @override
  State<WealthHistoryChart> createState() => _WealthHistoryChartState();
}

class _WealthHistoryChartState extends State<WealthHistoryChart> with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
    ..forward();

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  void _pick(double dx, double width) {
    final n = widget.points.length;
    final index = ((dx / width) * (n - 1)).round().clamp(0, n - 1);
    if (index != widget.selected) widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final selected = widget.points[widget.selected.clamp(0, widget.points.length - 1)];
    return Semantics(
      label: t.assets.wealth.chartLabel,
      value: t.assets.wealth.pointLabel(
        period: selected.period.name,
        amount: AppMoneyFormatter.format(selected.point.total),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _pick(d.localPosition.dx, width),
            onHorizontalDragUpdate: (d) => _pick(d.localPosition.dx, width),
            child: SizedBox(
              height: widget.height,
              width: width,
              child: AnimatedBuilder(
                animation: _draw,
                builder: (context, _) => CustomPaint(
                  painter: _ChartPainter(
                    totals: [for (final p in widget.points) p.point.total],
                    stale: [for (final p in widget.points) p.point.hasStale],
                    selected: widget.selected,
                    progress: Curves.easeOutCubic.transform(_draw.value),
                    line: ds.colors.actionPrimary,
                    guide: ds.colors.outlineSubtle,
                    surface: ds.colors.surfaceCard,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.totals,
    required this.stale,
    required this.selected,
    required this.progress,
    required this.line,
    required this.guide,
    required this.surface,
  });

  final List<int> totals;
  final List<bool> stale;
  final int selected;
  final double progress;
  final Color line;
  final Color guide;
  final Color surface;

  static const _padTop = 14.0;
  static const _padBottom = 10.0;
  static const _padX = 8.0;

  List<Offset> _offsets(Size size) {
    final lo = totals.reduce(math.min);
    final hi = totals.reduce(math.max);
    final span = (hi - lo) == 0 ? math.max(hi.abs(), 1) * 0.2 : (hi - lo).toDouble();
    final floor = (hi - lo) == 0 ? lo - span : lo - span * 0.12;
    final ceil = (hi - lo) == 0 ? hi + span : hi + span * 0.12;
    final h = size.height - _padTop - _padBottom;
    final w = size.width - _padX * 2;
    return [
      for (var i = 0; i < totals.length; i++)
        Offset(
          _padX + w * (totals.length == 1 ? 0.5 : i / (totals.length - 1)),
          _padTop + h * (1 - (totals[i] - floor) / (ceil - floor)),
        ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (totals.length < 2) return;
    final pts = _offsets(size);

    // Panduan mendatar garis rambut.
    final hair = Paint()
      ..color = guide
      ..strokeWidth = 1;
    for (final f in const [0.0, 0.5, 1.0]) {
      final y = _padTop + (size.height - _padTop - _padBottom) * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), hair);
    }

    // Kurva halus (titik tengah antar titik sebagai simpul).
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final mid = Offset((pts[i - 1].dx + pts[i].dx) / 2, (pts[i - 1].dy + pts[i].dy) / 2);
      path.quadraticBezierTo(pts[i - 1].dx, pts[i - 1].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    // Tergambar dari kiri ke kanan.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    final fill = Path.from(path)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [line.withValues(alpha: 0.22), line.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    // Garis tegak dan titik; hanya yang sudah terjangkau kurva.
    final sel = selected.clamp(0, pts.length - 1);
    if (pts[sel].dx <= size.width * progress) {
      canvas.drawLine(
        Offset(pts[sel].dx, pts[sel].dy),
        Offset(pts[sel].dx, size.height - _padBottom),
        Paint()
          ..color = line.withValues(alpha: 0.35)
          ..strokeWidth = 1.5,
      );
    }
    final dotCount = pts.length <= 24;
    for (var i = 0; i < pts.length; i++) {
      if (pts[i].dx > size.width * progress) continue;
      final isSel = i == sel;
      if (!dotCount && !isSel) continue;
      if (isSel) canvas.drawCircle(pts[i], 11, Paint()..color = line.withValues(alpha: 0.18));
      final r = isSel ? 5.5 : 3.5;
      if (stale[i]) {
        canvas.drawCircle(pts[i], r, Paint()..color = surface);
        canvas.drawCircle(
          pts[i],
          r,
          Paint()
            ..color = line
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      } else {
        canvas.drawCircle(pts[i], r + 1.5, Paint()..color = surface);
        canvas.drawCircle(pts[i], r, Paint()..color = line);
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.progress != progress || old.selected != selected || old.totals != totals || old.stale != stale || old.line != line;
}
