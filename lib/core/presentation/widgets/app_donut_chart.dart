import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Satu irisan [AppDonutChart]: nilainya (satuan bebas, hanya perbandingan
/// yang dipakai) dan warna.
class DonutSlice {
  /// Membuat [DonutSlice].
  const DonutSlice({required this.value, required this.color});

  /// Nilai irisan; irisan bernilai 0 atau kurang tidak digambar.
  final int value;

  /// Warna irisan.
  final Color color;
}

/// Diagram donat porsi kategori (komponen DonutChart, Riwayat › Analisis).
///
/// Lingkar 216, tebal 24, mulai jam 12 searah jarum jam, celah 2,5 antar
/// irisan, ujung rata (`tk-donut`). Irisan terpilih ([selected]) menyala dan
/// yang lain meredup ke 25%. [center] ditaruh di tengah (jenis dan total,
/// atau kategori terpilih). Mengetuk irisan memanggil [onSelect] dengan
/// indeksnya; legenda ([AppLegendRow]) tetap jalan utama dan jalan untuk
/// pembaca layar.
class AppDonutChart extends StatelessWidget {
  /// Membuat [AppDonutChart].
  const AppDonutChart({
    required this.slices,
    required this.center,
    required this.semanticsLabel,
    this.selected,
    this.onSelect,
    super.key,
  });

  /// Irisan, urut searah jarum jam dari jam 12.
  final List<DonutSlice> slices;

  /// Isi lubang donat.
  final Widget center;

  /// Label ringkas seluruh diagram, mis. "Pengeluaran September: Belanja 27%, …".
  final String semanticsLabel;

  /// Indeks irisan terpilih, atau `null` = tanpa pilihan.
  final int? selected;

  /// Dipanggil dengan indeks irisan yang diketuk.
  final ValueChanged<int>? onSelect;

  /// Sisi kotak diagram.
  static const double size = 216;

  /// Tebal cincin.
  static const double stroke = 24;

  /// Jari-jari garis tengah cincin.
  static const double radius = 96;

  /// Celah antar irisan, dalam satuan panjang busur.
  static const double gap = 2.5;

  /// Panjang busur minimal supaya irisan sangat kecil tetap terlihat.
  static const double minArc = 1.5;

  /// Indeks irisan di titik [local] pada kotak [size], atau `null` bila
  /// di luar cincin. Dipisah supaya bisa diuji tanpa menyentuh layar.
  static int? sliceAt(Offset local, List<DonutSlice> slices) {
    const center = Offset(size / 2, size / 2);
    final delta = local - center;
    final distance = delta.distance;
    if (distance < radius - stroke / 2 - 8 || distance > size / 2) return null;
    final total = slices.fold<int>(0, (sum, s) => sum + (s.value > 0 ? s.value : 0));
    if (total == 0) return null;
    // Sudut dari jam 12 searah jarum jam, dalam panjang busur.
    var angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    final along = angle * radius;
    const circumference = 2 * math.pi * radius;
    var at = 0.0;
    for (final (i, slice) in slices.indexed) {
      if (slice.value <= 0) continue;
      final full = slice.value / total * circumference;
      if (along >= at && along < at + full) return i;
      at += full;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Semantics(
            label: semanticsLabel,
            image: true,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: onSelect == null
                  ? null
                  : (details) {
                      final index = sliceAt(details.localPosition, slices);
                      if (index != null) onSelect!(index);
                    },
              child: CustomPaint(
                size: const Size.square(size),
                painter: _DonutPainter(slices: slices, selected: selected),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: IgnorePointer(
                child: Semantics(
                  liveRegion: true,
                  child: Center(child: center),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.slices, required this.selected});

  final List<DonutSlice> slices;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<int>(0, (sum, s) => sum + (s.value > 0 ? s.value : 0));
    if (total == 0) return;
    const r = AppDonutChart.radius;
    const circumference = 2 * math.pi * r;
    final visible = slices.where((s) => s.value > 0).length;
    final gap = visible > 1 ? AppDonutChart.gap : 0.0;
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: r);
    var at = 0.0;
    for (final (i, slice) in slices.indexed) {
      if (slice.value <= 0) continue;
      final full = slice.value / total * circumference;
      final length = math.max(AppDonutChart.minArc, full - gap);
      final dim = selected != null && selected != i;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppDonutChart.stroke
        ..strokeCap = StrokeCap.butt
        ..color = dim ? slice.color.withValues(alpha: 0.25) : slice.color;
      canvas.drawArc(rect, -math.pi / 2 + at / r, length / r, false, paint);
      at += full;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.selected != selected || !_sameSlices(old.slices, slices);

  static bool _sameSlices(List<DonutSlice> a, List<DonutSlice> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value || a[i].color != b[i].color) return false;
    }
    return true;
  }
}
