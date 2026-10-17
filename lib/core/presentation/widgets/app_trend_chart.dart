import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:saldough/core/currency/amount_visibility.dart';
import 'package:saldough/core/theme/theme.dart';

/// Satu kolom [AppTrendChart]: sepasang batang (pemasukan dan pengeluaran)
/// beserta label di bawahnya.
class TrendColumn {
  /// Membuat [TrendColumn].
  const TrendColumn({
    required this.label,
    required this.income,
    required this.expense,
    required this.netText,
    required this.semanticsLabel,
    this.caption,
  });

  /// Label periode di bawah kolom, mis. "Sep".
  final String label;

  /// Pemasukan (sen), tinggi batang kiri.
  final int income;

  /// Pengeluaran (sen), tinggi batang kanan.
  final int expense;

  /// Selisih ringkas di bawah label, mis. "+3,2 jt"; kosong bila tak ada.
  final String netText;

  /// Keterangan kecil di bawahnya: "s.d. 10 Okt" atau "24 hari".
  final String? caption;

  /// Label pembaca layar yang lengkap untuk kolom ini.
  final String semanticsLabel;
}

/// Tren enam periode (komponen TrendChart, ADR-034): pemasukan `positive` di
/// kiri dan pengeluaran `ink` di kanan, tiap batang tumpukan kotak 6px; garis
/// bantu `line`, garis dasar `ink-3`, periode terpilih berpita `surface-2`.
///
/// Enam slot tetap, rata kanan: periode sebelum pencatatan pertama tidak
/// digambar (slotnya kosong), bukan nol. Mengetuk kolom memilihnya.
/// Nominal tersembunyi: batang tetap tampil, label sumbu hilang.
class AppTrendChart extends StatelessWidget {
  /// Membuat [AppTrendChart] untuk [columns] (paling banyak [slots]).
  const AppTrendChart({
    required this.columns,
    required this.selected,
    required this.onSelect,
    required this.axisLabel,
    this.slots = 6,
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
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final offset = slots - columns.length;
    final hi = columns.fold<int>(0, (m, c) => math.max(m, math.max(c.income, c.expense)));
    final scale = scaleFor(hi);
    double yOf(double value) => _base - value / scale.max * (_base - _top);
    final ticks = [for (var t = scale.step; t <= scale.max + 1; t += scale.step) t];
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final area = constraints.maxWidth - axisWidth;
          final slot = area / slots;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrendPainter(
                    columns: columns,
                    offset: offset,
                    slots: slots,
                    selected: selected,
                    scaleMax: scale.max,
                    ticks: ticks,
                    area: area,
                    positive: colors.positive,
                    ink: colors.ink,
                    line: colors.line,
                    base: colors.ink3,
                    band: colors.surface2,
                  ),
                ),
              ),
              if (!AmountVisibility.hidden)
                for (final tick in ticks)
                  Positioned(
                    right: 0,
                    top: yOf(tick) - 7,
                    child: ExcludeSemantics(
                      child: Text(
                        axisLabel(tick.round()),
                        style: textTheme.labelSmall?.copyWith(color: colors.ink2, fontSize: 11, height: 14 / 11),
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
                          selected: i == selected,
                          onTap: () => onSelect(i),
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final color = selected ? colors.ink : colors.ink2;
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
                style: textTheme.labelMedium?.copyWith(
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
                style: textTheme.labelSmall?.copyWith(color: color, fontSize: 11, height: 14 / 11),
              ),
              if (column.caption case final caption?)
                Text(
                  caption,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: textTheme.labelSmall?.copyWith(color: colors.ink3, fontSize: 11, height: 13 / 11),
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
    required this.scaleMax,
    required this.ticks,
    required this.area,
    required this.positive,
    required this.ink,
    required this.line,
    required this.base,
    required this.band,
  });

  final List<TrendColumn> columns;
  final int offset;
  final int slots;
  final int selected;
  final double scaleMax;
  final List<double> ticks;
  final double area;
  final Color positive;
  final Color ink;
  final Color line;
  final Color base;
  final Color band;

  static const _brick = 6.0;
  static const _pitch = 8.0;
  static const _barWidth = 10.0;

  double _y(double value) => AppTrendChart._base - value / scaleMax * (AppTrendChart._base - AppTrendChart._top);

  @override
  void paint(Canvas canvas, Size size) {
    final slot = area / slots;
    if (columns.isNotEmpty) {
      canvas.drawRect(
        Rect.fromLTWH(slot * (offset + selected) + 1, 0, slot - 2, size.height),
        Paint()..color = band,
      );
    }
    final grid = Paint()
      ..color = line
      ..strokeWidth = 1
      ..isAntiAlias = false;
    for (final tick in ticks) {
      final y = _y(tick).roundToDouble() + 0.5;
      canvas.drawLine(Offset(0, y), Offset(area, y), grid);
    }
    canvas.drawLine(
      const Offset(0, AppTrendChart._base + 0.5),
      Offset(area, AppTrendChart._base + 0.5),
      Paint()
        ..color = base
        ..strokeWidth = 1
        ..isAntiAlias = false,
    );
    for (final (i, column) in columns.indexed) {
      final cx = slot * (offset + i) + slot / 2;
      _stack(canvas, cx - _barWidth - 1, column.income, positive);
      _stack(canvas, cx + 1, column.expense, ink);
    }
  }

  /// Batang: tumpukan kotak 6px berjarak 2px dari garis dasar; sisa tinggi
  /// di bawah satu kotak digambar sebagai kotak yang lebih pendek.
  void _stack(Canvas canvas, double x, int value, Color color) {
    if (value <= 0) return;
    final height = value / scaleMax * (AppTrendChart._base - AppTrendChart._top);
    final full = (height / _pitch).floor();
    final rest = height - full * _pitch;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    for (var i = 0; i < full; i++) {
      canvas.drawRect(Rect.fromLTWH(x, AppTrendChart._base - _pitch * i - _brick, _barWidth, _brick), paint);
    }
    if (rest > 0.5) {
      final h = math.min(rest, _brick);
      canvas.drawRect(Rect.fromLTWH(x, AppTrendChart._base - _pitch * full - h, _barWidth, h), paint);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.columns != columns ||
      old.selected != selected ||
      old.scaleMax != scaleMax ||
      old.area != area ||
      old.positive != positive ||
      old.ink != ink ||
      old.line != line ||
      old.base != base ||
      old.band != band;
}
