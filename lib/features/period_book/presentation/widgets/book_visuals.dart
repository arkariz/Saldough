import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';

/// Warna irisan donat dan batang kategori: dari token tema, jadi mengikuti
/// preset warna dan mode gelap. Urutan tetap supaya irisan dan legenda cocok.
List<Color> bookPalette(BuildContext context) {
  final c = context.ds.colors;
  return [c.actionPrimary, c.stampGoldDeep, c.info, c.heroAccentWarm, c.heroAccent, c.income, c.secondary, c.warning];
}

/// Latar adegan buku: gradasi lembut dari warna utama ke kanvas, dengan
/// serpihan daun, koin, dan kilau yang melayang pelan (satu `Ticker`). Dipakai
/// sampul, kepala ritual, dan halaman Kata Tanuki supaya layar tidak kosong.
/// Gerak dikurangi: serpihan diam di tempatnya.
class BookScene extends StatefulWidget {
  /// Membuat [BookScene].
  const BookScene({required this.child, this.radius = 24, this.intensity = 1, super.key});

  /// Isi di atas adegan.
  final Widget child;

  /// Radius sudut.
  final double radius;

  /// 0-1: banyaknya serpihan dan kuat warna latar.
  final double intensity;

  @override
  State<BookScene> createState() => _BookSceneState();
}

class _BookSceneState extends State<BookScene> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 12));

  // (x, y, ukuran, fase, aset)
  static const List<(double, double, double, double, String)> _pieces = [
    (0.08, 0.14, 22.0, 0.00, ClayIcons.confettiLeaf),
    (0.90, 0.10, 18.0, 0.25, ClayIcons.sparkle),
    (0.16, 0.62, 16.0, 0.50, ClayIcons.sparkle),
    (0.86, 0.58, 24.0, 0.15, ClayIcons.confettiLeaf),
    (0.05, 0.88, 20.0, 0.70, ClayIcons.tierCoin),
    (0.93, 0.86, 18.0, 0.40, ClayIcons.confettiStar),
    (0.50, 0.05, 14.0, 0.85, ClayIcons.sparkle),
    (0.74, 0.30, 16.0, 0.60, ClayIcons.tierCoin),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DsMotion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final count = (_pieces.length * widget.intensity).round().clamp(2, _pieces.length);
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(c.actionPrimary.withValues(alpha: 0.16 * widget.intensity), c.surfaceCard),
              Color.alphaBlend(c.stampGold.withValues(alpha: 0.10 * widget.intensity), c.surfaceCard),
            ],
          ),
          border: Border.all(color: c.outlineSubtle),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: LayoutBuilder(
                    builder: (context, box) => AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) => Stack(
                        children: [
                          for (final (x, y, size, phase, asset) in _pieces.take(count))
                            Positioned(
                              left: box.maxWidth * x - size / 2,
                              top: box.maxHeight * y - size / 2 + math.sin((_c.value + phase) * math.pi * 2) * 6,
                              child: Opacity(
                                opacity: 0.55,
                                child: Transform.rotate(
                                  angle: math.sin((_c.value + phase) * math.pi * 2) * 0.4,
                                  child: SvgPicture.asset(asset, width: size, height: size),
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
            widget.child,
          ],
        ),
      ),
    );
  }
}

/// Donat (rupa D6, halaman Ke mana uang pergi): irisan menyapu 900 ms
/// `easeOutExpo`, celah kecil antar irisan, dan isi tengah bebas. Irisan
/// berukuran proporsional [fractions] (jumlahnya boleh kurang dari 1).
class DonutChart extends StatelessWidget {
  /// Membuat [DonutChart].
  const DonutChart({required this.fractions, required this.colors, required this.center, this.size = 190, super.key});

  /// Bagian tiap irisan (0-1).
  final List<double> fractions;

  /// Warna tiap irisan (urut sama).
  final List<Color> colors;

  /// Isi di tengah lubang.
  final Widget center;

  /// Sisi kotak donat.
  final double size;

  @override
  Widget build(BuildContext context) {
    final track = context.ds.colors.surfaceSunken;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: DsMotion.reduced(context) ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: DsMotion.easeOutExpo,
            builder: (context, t, _) => CustomPaint(
              size: Size.square(size),
              painter: _DonutPainter(fractions: fractions, colors: colors, track: track, progress: t),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(size * 0.22),
            child: Center(child: center),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.fractions, required this.colors, required this.track, required this.progress});

  final List<double> fractions;
  final List<Color> colors;
  final Color track;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.16;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: (size.width - stroke) / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    const gap = 0.035;
    var start = -math.pi / 2;
    for (var i = 0; i < fractions.length; i++) {
      final sweep = fractions[i].clamp(0.0, 1.0) * math.pi * 2 * progress;
      if (sweep <= gap) {
        start += sweep;
        continue;
      }
      canvas.drawArc(
        rect,
        start + gap / 2,
        sweep - gap,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt
          ..color = colors[i % colors.length],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.fractions != fractions || old.colors != colors;
}

/// Dua batang mendatar yang dibandingkan skalanya (Pemasukan vs Pengeluaran,
/// halaman Arus; "Biasanya" vs "Periode ini", halaman Dibanding biasanya).
/// Memanjang 900 ms; tanpa warna peringatan.
class PairBars extends StatelessWidget {
  /// Membuat [PairBars].
  const PairBars({
    required this.labelA,
    required this.valueA,
    required this.textA,
    required this.labelB,
    required this.valueB,
    required this.textB,
    this.colorA,
    this.colorB,
    this.onDark = false,
    super.key,
  });

  /// Di atas kartu gelap (hero): teks dan jalur memakai warna `onHero`.
  final bool onDark;

  /// Label, nilai, dan teks nominal batang pertama.
  final String labelA;

  /// Nilai pertama (sen).
  final int valueA;

  /// Teks nominal pertama (sudah diformat).
  final String textA;

  /// Label batang kedua.
  final String labelB;

  /// Nilai kedua (sen).
  final int valueB;

  /// Teks nominal kedua.
  final String textB;

  /// Warna batang pertama; bawaan `income`.
  final Color? colorA;

  /// Warna batang kedua; bawaan `actionPrimary`.
  final Color? colorB;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final maxValue = math.max(1, math.max(valueA.abs(), valueB.abs()));
    Widget bar(String label, int value, String text, Color color) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: ds.typography.bodySm.copyWith(color: onDark ? c.onHeroMuted : c.textSecondary)),
            ),
            Text(text, style: ds.typography.pixelLabel.copyWith(color: onDark ? c.onHero : c.textPrimary)),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, box) => TweenAnimationBuilder<double>(
            tween: Tween(begin: DsMotion.reduced(context) ? value.abs() / maxValue : 0, end: value.abs() / maxValue),
            duration: const Duration(milliseconds: 900),
            curve: DsMotion.easeOutExpo,
            builder: (context, v, _) => Stack(
              children: [
                Container(
                  height: 10,
                  width: box.maxWidth,
                  decoration: BoxDecoration(
                    color: onDark ? Colors.white.withValues(alpha: 0.16) : c.surfaceSunken,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Container(
                  height: 10,
                  width: math.max(6, box.maxWidth * v),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    return Column(
      children: [
        bar(labelA, valueA, textA, colorA ?? (onDark ? c.heroAccent : c.income)),
        const SizedBox(height: 10),
        bar(labelB, valueB, textB, colorB ?? (onDark ? c.heroAccentWarm : c.actionPrimary)),
      ],
    );
  }
}

/// Chip ringkas dengan ikon clay (cover: "21 catatan", "31 hari").
class BookChip extends StatelessWidget {
  /// Membuat [BookChip].
  const BookChip({required this.asset, required this.label, super.key});

  /// Ikon clay.
  final String asset;

  /// Teks.
  final String label;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.outlineSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: SvgPicture.asset(asset, width: 22, height: 22)),
          const SizedBox(width: 6),
          Text(
            label,
            style: ds.typography.bodySm.copyWith(color: c.textSecondary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Kartu hero hijau (gradasi `heroSurface` ke `heroGlow`) dengan teks terang,
/// dipakai halaman Arus dan Rutin dan rencana.
class BookHero extends StatelessWidget {
  /// Membuat [BookHero].
  const BookHero({required this.child, this.padding = const EdgeInsets.all(18), super.key});

  /// Isi.
  final Widget child;

  /// Padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: const Alignment(-0.8, -1),
          end: const Alignment(0.9, 1),
          colors: [
            Color.lerp(c.heroSurface, c.heroGlow, 0.25)!,
            c.heroSurface,
            Color.lerp(c.heroSurface, Colors.black, 0.25)!,
          ],
          stops: const [0, 0.5, 1],
        ),
        border: Border.all(color: c.heroBorder),
      ),
      child: child,
    );
  }
}
