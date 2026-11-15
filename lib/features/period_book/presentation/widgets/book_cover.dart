import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';

/// Sampul buku periode (rupa D5, `DsBookCover`): gradasi hijau, bingkai emas
/// tipis, punggung gelap di kiri, nama periode, Tanuki di kanan bawah, dan
/// [seals] di dasar. Dipakai sampul (232x320) dan Rak Buku (kecil, T-27.7).
///
/// Warna: gradasi `stampSeal`/`stampSealDeep` dan bingkai `stampGold` (token
/// segel; sama dengan sampul di terang maupun gelap karena selalu permukaan
/// sendiri).
class BookCover extends StatelessWidget {
  /// Membuat [BookCover].
  const BookCover({
    required this.eyebrow,
    required this.title,
    required this.semanticLabel,
    this.subtitle,
    this.seals = const [],
    this.width = 232,
    super.key,
  });

  /// Teks kecil di atas ("Buku periode").
  final String eyebrow;

  /// Nama periode.
  final String title;

  /// Label pembaca layar ("Buku Oktober").
  final String semanticLabel;

  /// Tahun atau "Periode peralihan · n hari".
  final String? subtitle;

  /// Segel di dasar (sudah jadi widget, mis. `DsStampSeal`).
  final List<Widget> seals;

  /// Lebar; tinggi mengikuti 232:320.
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final k = width / 232;
    final height = 320 * k;
    return Semantics(
      label: semanticLabel,
      container: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-0.8, -1),
                end: const Alignment(0.8, 1),
                colors: [c.stampSeal, c.stampSealDeep],
              ),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(6 * k), right: Radius.circular(16 * k)),
              boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 24, offset: Offset(10, 14))],
            ),
            child: Stack(
              children: [
                // Punggung gelap.
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 14 * k,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(6 * k)),
                    ),
                  ),
                ),
                // Bingkai emas.
                Positioned.fill(
                  left: 22 * k,
                  top: 10 * k,
                  right: 10 * k,
                  bottom: 10 * k,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: c.stampGold.withValues(alpha: 0.65), width: 1.5),
                      borderRadius: BorderRadius.circular(10 * k),
                    ),
                  ),
                ),
                Positioned(
                  left: 38 * k,
                  right: 24 * k,
                  top: 30 * k,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        style: context.ds.typography.pixelCaption.copyWith(color: c.stampGold, fontSize: 10 * k),
                      ),
                      SizedBox(height: 6 * k),
                      Text(
                        title,
                        style: context.ds.typography.headlineMd.copyWith(
                          color: Colors.white,
                          fontSize: 26 * k,
                          height: 30 / 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 4 * k),
                        Text(
                          subtitle!.toUpperCase(),
                          style: context.ds.typography.pixelCaption.copyWith(color: c.stampGold, fontSize: 10 * k),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  right: 22 * k,
                  bottom: 78 * k,
                  child: SvgPicture.asset(ClayIcons.mascot, width: 74 * k, height: 74 * k),
                ),
                if (seals.isNotEmpty)
                  Positioned(
                    left: 34 * k,
                    right: 22 * k,
                    bottom: 22 * k,
                    child: Wrap(spacing: 6, runSpacing: 6, children: seals),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Memiringkan [child] pada sumbu Y seperti buku melayang (rupa D5: −18° ke
/// −12°, 4 dtk, bolak-balik). Diam saat gerak dikurangi.
class FloatingBook extends StatefulWidget {
  /// Membuat [FloatingBook].
  const FloatingBook({required this.child, super.key});

  /// Buku.
  final Widget child;

  @override
  State<FloatingBook> createState() => _FloatingBookState();
}

class _FloatingBookState extends State<FloatingBook> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DsMotion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = DsMotion.reduced(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final angle = (reduced ? -15 : -18 + 6 * Curves.easeInOut.transform(_c.value)) * math.pi / 180;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
