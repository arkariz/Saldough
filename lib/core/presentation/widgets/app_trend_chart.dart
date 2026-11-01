import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:saldough/core/currency/amount_visibility.dart';
import 'package:saldough/core/design_system/design_system.dart';

/// Satu kolom [AppTrendChart]: sepasang batang (pemasukan dan pengeluaran)
/// beserta label di bawahnya.
class TrendColumn {
  /// Membuat [TrendColumn].
  const TrendColumn({
    required this.label,
    required this.income,
    required this.expense,
    required this.semanticsLabel,
    this.netText = '',
    this.caption,
  });

  /// Label periode di bawah kolom, mis. "Sep".
  final String label;

  /// Pemasukan (sen), tinggi batang kiri; diabaikan pada grafik satu besaran.
  final int income;

  /// Pengeluaran (sen), tinggi batang kanan; pada grafik satu besaran, nilainya.
  final int expense;

  /// Selisih ringkas di bawah label, mis. "+3,2 jt"; kosong bila tak ada.
  final String netText;

  /// Keterangan kecil di bawahnya: "s.d. 10 Okt" atau "24 hari".
  final String? caption;

  /// Label pembaca layar yang lengkap untuk kolom ini.
  final String semanticsLabel;
}

/// Tren enam periode (grafik batang v2): pemasukan `income` di kiri dan
/// pengeluaran `error` di kanan, batang bulat berkilap tipis; garis bantu
/// putus-putus, garis dasar rambut, periode terpilih berpita `actionPrimary`
/// tipis yang meluncur, kolom lain meredup.
///
/// Batang tumbuh dari garis dasar berurutan dari kiri saat grafik tampil dan
/// saat datanya berganti; pita meluncur saat kolom dipilih. Diam (tanpa
/// animasi) bila gerak dikurangi.
///
/// Enam slot tetap, rata kanan: periode sebelum pencatatan pertama tidak
/// digambar (slotnya kosong), bukan nol. Mengetuk kolom memilihnya.
/// Nominal tersembunyi: batang tetap tampil, label sumbu hilang.
class AppTrendChart extends StatefulWidget {
  /// Membuat [AppTrendChart] untuk [columns] (paling banyak [slots]).
  const AppTrendChart({
    required this.columns,
    required this.selected,
    required this.onSelect,
    required this.axisLabel,
    this.slots = 6,
    this.single = false,
    this.average,
    this.averageLabel,
    super.key,
  });

  /// Kolom, urut dari yang tertua; yang terakhir paling kanan.
  final List<TrendColumn> columns;

  /// Indeks kolom terpilih di [columns].
  final int selected;

  /// Dipanggil dengan indeks kolom yang diketuk.
  final ValueChanged<int> onSelect;

  /// Label sumbu ringkas untuk sebuah nominal, mis. "15 jt".
  final String Function(int sen) axisLabel;

  /// Jumlah slot.
  final int slots;

  /// Satu besaran (Rincian kategori): satu batang 14px per kolom dari
  /// [TrendColumn.expense], bukan sepasang.
  final bool single;

  /// Tinggi garis rata-rata putus-putus (sen); `null` = tanpa garis.
  final int? average;

  /// Label garis rata-rata, mis. "rata-rata 3 bulan".
  final String? averageLabel;

  /// Tinggi seluruh grafik.
  static const height = 186.0;

  /// Lebar kolom label sumbu di kanan.
  static const axisWidth = 36.0;

  static const _top = 8.0;
  static const _base = 116.0;

  /// Skala sumbu untuk nilai tertinggi [hi] (sen): langkah rapi dan batas atas
  /// kelipatannya (1/2/2,5/5 × 10ⁿ), sehingga paling banyak sekitar tiga garis.
  static ({double step, double max}) scaleFor(num hi) {
    final top = math.max(hi.toDouble(), 1);
    final raw = top / 3;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final step = [1, 2, 2.5, 5, 10].map((m) => m * magnitude).firstWhere((c) => c >= raw);
    return (step: step, max: (top / step).ceil() * step);
  }

  @override
  State<AppTrendChart> createState() => _AppTrendChartState();
}

class _AppTrendChartState extends State<AppTrendChart> with SingleTickerProviderStateMixin {
  late final AnimationController _grow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (DsMotion.reduced(context)) {
      _grow.value = 1;
    } else {
      _grow.forward();
    }
  }

  @override
  void didUpdateWidget(AppTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameData(oldWidget.columns, widget.columns) && !DsMotion.reduced(context)) _grow.forward(from: 0);
  }

  static bool _sameData(List<TrendColumn> a, List<TrendColumn> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].income != b[i].income || a[i].expense != b[i].expense) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final reduced = DsMotion.reduced(context);
    final columns = widget.columns;
    final slots = widget.slots;
    final offset = slots - columns.length;
    final hi = columns.fold<int>(
      widget.average ?? 0,
      (m, col) => math.max(m, widget.single ? col.expense : math.max(col.income, col.expense)),
    );
    final scale = AppTrendChart.scaleFor(hi);
    double yOf(double value) => AppTrendChart._base - value / scale.max * (AppTrendChart._base - AppTrendChart._top);
    final ticks = [for (var t = scale.step; t <= scale.max + 1; t += scale.step) t];
    final tickStyle = ds.typography.labelMd.copyWith(color: c.textMuted, fontSize: 11, height: 14 / 11);
    return SizedBox(
      height: AppTrendChart.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final area = constraints.maxWidth - AppTrendChart.axisWidth;
          final slot = area / slots;
          return Stack(
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: widget.selected.toDouble()),
                  duration: reduced ? Duration.zero : const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  builder: (context, bandAt, _) => CustomPaint(
                    painter: _TrendPainter(
                      columns: columns,
                      offset: offset,
                      slots: slots,
                      selected: widget.selected,
                      bandAt: bandAt,
                      scaleMax: scale.max,
                      ticks: ticks,
                      area: area,
                      income: c.income,
                      expense: c.error,
                      single: widget.single,
                      average: widget.average,
                      mark: c.actionPrimary,
                      dash: c.textSecondary,
                      line: c.outlineSubtle,
                      base: c.outline,
                      band: c.actionPrimary.withValues(alpha: 0.08),
                      grow: _grow,
                    ),
                  ),
                ),
              ),
              if (!AmountVisibility.hidden)
                for (final tick in ticks)
                  Positioned(
                    right: 0,
                    top: yOf(tick) - 7,
                    child: ExcludeSemantics(child: Text(widget.axisLabel(tick.round()), style: tickStyle)),
                  ),
              if (widget.average case final avg? when widget.averageLabel != null)
                Positioned(
                  left: 0,
                  bottom: AppTrendChart.height - yOf(avg.toDouble()).roundToDouble() + 1,
                  child: ExcludeSemantics(
                    child: Container(
                      color: c.surfaceCard,
                      padding: const EdgeInsets.only(right: 4, bottom: 2),
                      child: Text(widget.averageLabel!, style: tickStyle.copyWith(color: c.textSecondary)),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: area,
                child: Row(
                  children: [
                    for (var i = 0; i < offset; i++) SizedBox(width: slot),
                    for (final (i, column) in columns.indexed)
                      SizedBox(
                        width: slot,
                        child: _ColumnButton(
                          key: ValueKey('trend-col-$i'),
                          column: column,
                          selected: i == widget.selected,
                          onTap: () => widget.onSelect(i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ColumnButton extends StatelessWidget {
  const _ColumnButton({required this.column, required this.selected, required this.onTap, super.key});

  final TrendColumn column;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final color = selected ? c.textPrimary : c.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: column.semanticsLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                column.label,
                maxLines: 1,
                style: ds.typography.labelMd.copyWith(
                  color: color,
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              Text(
                column.netText,
                maxLines: 1,
                softWrap: false,
                style: ds.typography.labelMd.copyWith(color: color, fontSize: 11, height: 14 / 11),
              ),
              if (column.caption case final caption?)
                Text(
                  caption,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: ds.typography.labelMd.copyWith(color: c.textMuted, fontSize: 11, height: 13 / 11),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.columns,
    required this.offset,
    required this.slots,
    required this.selected,
    required this.bandAt,
    required this.scaleMax,
    required this.ticks,
    required this.area,
    required this.income,
    required this.expense,
    required this.single,
    required this.average,
    required this.mark,
    required this.dash,
    required this.line,
    required this.base,
    required this.band,
    required this.grow,
  }) : super(repaint: grow);

  final List<TrendColumn> columns;
  final int offset;
  final int slots;
  final int selected;
  final double bandAt;
  final double scaleMax;
  final List<double> ticks;
  final double area;
  final Color income;
  final Color expense;
  final bool single;
  final int? average;
  final Color mark;
  final Color dash;
  final Color line;
  final Color base;
  final Color band;
  final Animation<double> grow;

  static const _barWidth = 10.0;

  double _y(double value) => AppTrendChart._base - value / scaleMax * (AppTrendChart._base - AppTrendChart._top);

  @override
  void paint(Canvas canvas, Size size) {
    final slot = area / slots;
    if (columns.isNotEmpty) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(slot * (offset + bandAt) + 1, 0, slot - 2, size.height),
          const Radius.circular(12),
        ),
        Paint()..color = band,
      );
    }
    final grid = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (final tick in ticks) {
      final y = _y(tick).roundToDouble() + 0.5;
      for (var x = 0.0; x < area; x += 7) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 3, area), y), grid);
      }
    }
    canvas.drawLine(
      const Offset(0, AppTrendChart._base + 0.5),
      Offset(area, AppTrendChart._base + 0.5),
      Paint()
        ..color = base
        ..strokeWidth = 1,
    );
    for (final (i, column) in columns.indexed) {
      final cx = slot * (offset + i) + slot / 2;
      // Tumbuh berurutan dari kiri; kolom lain meredup agar yang terpilih menonjol.
      final t = Curves.easeOutCubic.transform(((grow.value - i * 0.07) / 0.65).clamp(0.0, 1.0));
      final alpha = columns.length > 1 && i != selected ? 0.55 : 1.0;
      if (single) {
        _bar(canvas, cx - 7, column.expense, mark.withValues(alpha: alpha), t, width: 14);
      } else {
        _bar(canvas, cx - _barWidth - 1, column.income, income.withValues(alpha: alpha), t);
        _bar(canvas, cx + 1, column.expense, expense.withValues(alpha: alpha), t);
      }
    }
    if (average case final avg?) {
      // Garis acuan putus-putus 4/3, bukan perkiraan.
      final y = _y(avg.toDouble()).roundToDouble() + 0.5;
      final paint = Paint()
        ..color = dash
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (var x = 0.0; x < area; x += 7) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, area), y), paint);
      }
    }
  }

  /// Batang bulat berkilap tipis yang tumbuh dari garis dasar; nilai tidak nol
  /// minimal setinggi 3px supaya tetap terlihat.
  void _bar(Canvas canvas, double x, int value, Color color, double progress, {double width = _barWidth}) {
    if (value <= 0) return;
    final scaled = value / scaleMax * (AppTrendChart._base - AppTrendChart._top);
    final full = scaled < 3 ? 3 : scaled;
    final height = full * progress;
    if (height < 0.5) return;
    final rect = Rect.fromLTWH(x, AppTrendChart._base - height, width, height);
    final r = math.min(width / 2, height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(color, Colors.white, 0.25)!, color],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndCorners(rect, topLeft: Radius.circular(r), topRight: Radius.circular(r)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.columns != columns ||
      old.selected != selected ||
      old.bandAt != bandAt ||
      old.scaleMax != scaleMax ||
      old.area != area ||
      old.income != income ||
      old.expense != expense ||
      old.single != single ||
      old.average != average ||
      old.mark != mark ||
      old.dash != dash ||
      old.line != line ||
      old.base != base ||
      old.band != band;
}
