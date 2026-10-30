import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';

/// Jenis gerak [DsAmbientParticle].
enum DsAmbientKind {
  /// Melayang naik sambil berayun dan berputar (daun).
  leaf,

  /// Naik-turun sambil berdenyut terang (kilau).
  sparkle,
}

/// Satu partikel hiasan latar.
@immutable
class DsAmbientParticle {
  /// Membuat partikel.
  const DsAmbientParticle({
    required this.kind,
    required this.glyph,
    required this.top,
    required this.left,
    required this.size,
    required this.delay,
    required this.period,
  });

  /// Jenis gerak.
  final DsAmbientKind kind;

  /// Karakter (emoji).
  final String glyph;

  /// Posisi atas, pecahan tinggi layar (0–1).
  final double top;

  /// Posisi kiri, pecahan lebar layar (0–1).
  final double left;

  /// Ukuran huruf.
  final double size;

  /// Tunda mulai (detik).
  final double delay;

  /// Lama satu siklus (detik).
  final double period;

  /// Dua belas partikel bawaan, mengikuti `reference/home-motion.html`.
  static const List<DsAmbientParticle> defaults = [
    DsAmbientParticle(kind: DsAmbientKind.leaf, glyph: '🍃', top: 0.12, left: 0.08, size: 18, delay: 0, period: 9.5),
    DsAmbientParticle(
      kind: DsAmbientKind.sparkle,
      glyph: '✨',
      top: 0.22,
      left: 0.88,
      size: 14,
      delay: 0.8,
      period: 3.4,
    ),
    DsAmbientParticle(kind: DsAmbientKind.leaf, glyph: '🍂', top: 0.38, left: 0.86, size: 16, delay: 1.4, period: 8.8),
    DsAmbientParticle(
      kind: DsAmbientKind.sparkle,
      glyph: '✨',
      top: 0.48,
      left: 0.06,
      size: 18,
      delay: 2.1,
      period: 4.2,
    ),
    DsAmbientParticle(kind: DsAmbientKind.leaf, glyph: '🍃', top: 0.62, left: 0.92, size: 19, delay: 2.7, period: 10.2),
    DsAmbientParticle(
      kind: DsAmbientKind.sparkle,
      glyph: '⭐',
      top: 0.74,
      left: 0.14,
      size: 12,
      delay: 1.1,
      period: 3.6,
    ),
    DsAmbientParticle(kind: DsAmbientKind.leaf, glyph: '🍃', top: 0.82, left: 0.8, size: 15, delay: 3.3, period: 9.1),
    DsAmbientParticle(kind: DsAmbientKind.sparkle, glyph: '✨', top: 0.18, left: 0.45, size: 16, delay: 0.5, period: 4),
    DsAmbientParticle(kind: DsAmbientKind.leaf, glyph: '🍂', top: 0.32, left: 0.72, size: 17, delay: 4.1, period: 8.4),
    DsAmbientParticle(
      kind: DsAmbientKind.sparkle,
      glyph: '✨',
      top: 0.56,
      left: 0.24,
      size: 14,
      delay: 2.9,
      period: 3.7,
    ),
    DsAmbientParticle(kind: DsAmbientKind.leaf, glyph: '🍃', top: 0.7, left: 0.58, size: 16, delay: 1.8, period: 11),
    DsAmbientParticle(
      kind: DsAmbientKind.sparkle,
      glyph: '✨',
      top: 0.88,
      left: 0.78,
      size: 15,
      delay: 3.8,
      period: 3.2,
    ),
  ];
}

/// Lapisan hiasan daun dan kilau yang melayang pelan. Satu `Ticker` untuk
/// semua partikel; tidak menerima sentuhan dan tidak dibacakan pembaca
/// layar. Tidak tampil sama sekali saat gerak dikurangi.
///
/// Pakai lewat [DsAmbientBackdrop] supaya lapisan berada **di belakang**
/// konten. Di acuan partikel berada di depan dan menimpa teks.
class DsAmbientLayer extends StatefulWidget {
  /// Membuat lapisan.
  const DsAmbientLayer({this.particles = DsAmbientParticle.defaults, this.opacity = 0.55, super.key});

  /// Partikel yang digambar.
  final List<DsAmbientParticle> particles;

  /// Keburaman maksimum seluruh lapisan.
  final double opacity;

  @override
  State<DsAmbientLayer> createState() => _DsAmbientLayerState();
}

class _DsAmbientLayerState extends State<DsAmbientLayer> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _seconds = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker((elapsed) => _seconds.value = elapsed.inMicroseconds / 1e6);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DsMotion.reduced(context)) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (DsMotion.reduced(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: LayoutBuilder(
            builder: (context, box) => ListenableBuilder(
              listenable: _seconds,
              builder: (context, _) => Opacity(
                opacity: widget.opacity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final p in widget.particles) _positioned(p, box.biggest),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _positioned(DsAmbientParticle p, Size area) {
    final u = math.max(0, _seconds.value - p.delay) / p.period;
    final text = Text(p.glyph, style: TextStyle(fontSize: p.size));
    final Widget view;
    switch (p.kind) {
      case DsAmbientKind.leaf:
        // `alternate`: maju lalu mundur, dengan easeInOut.
        final cycle = u % 2;
        final w = Curves.easeInOut.transform(cycle <= 1 ? cycle : 2 - cycle);
        final x = dsKeyframes(w, [(0, 0), (0.33, 22), (0.66, -18), (1, 0)]);
        final y = dsKeyframes(w, [(0, 0), (0.33, -30), (0.66, -60), (1, -90)]);
        final r = dsKeyframes(w, [(0, 0), (0.33, 22), (0.66, -15), (1, 360)]);
        view = Transform.translate(
          offset: Offset(x, y),
          child: Transform.rotate(angle: r * math.pi / 180, child: text),
        );
      case DsAmbientKind.sparkle:
        final s = (1 - math.cos(2 * math.pi * (u % 1))) / 2;
        view = Opacity(
          opacity: 0.45 + 0.5 * s,
          child: Transform.translate(
            offset: Offset(0, -20 * s),
            child: Transform.scale(scale: 0.85 + 0.4 * s, child: text),
          ),
        );
    }
    return Positioned(left: p.left * area.width, top: p.top * area.height, child: view);
  }
}

/// Menaruh [DsAmbientLayer] **di belakang** [child]. Kartu putih menutup
/// partikel, jadi daun dan kilau hanya terlihat di celah kanvas dan tidak
/// pernah menimpa teks.
class DsAmbientBackdrop extends StatelessWidget {
  /// Membuat latar hidup.
  const DsAmbientBackdrop({
    required this.child,
    this.particles = DsAmbientParticle.defaults,
    this.opacity = 0.55,
    super.key,
  });

  /// Konten halaman.
  final Widget child;

  /// Partikel yang digambar.
  final List<DsAmbientParticle> particles;

  /// Keburaman maksimum lapisan.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DsAmbientLayer(particles: particles, opacity: opacity),
        ),
        child,
      ],
    );
  }
}
