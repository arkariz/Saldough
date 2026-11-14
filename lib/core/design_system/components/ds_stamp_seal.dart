import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';

/// Ukuran segel (rupa buku-stempel §3): 34, 56, 120.
enum DsStampSealSize {
  /// 34, di snackbar.
  sm(34, 18),

  /// 56, di baris Buku Stempel.
  md(56, 30),

  /// 120, di lembar pengenalan dan detail.
  lg(120, 62);

  const DsStampSealSize(this.diameter, this.icon);

  /// Garis tengah segel.
  final double diameter;

  /// Sisi ikon clay di tengah.
  final double icon;
}

/// Segel bulat stempel: koin clay di dalam cincin emas (diraih) atau cincin
/// abu-abu dengan ikon pudar (terkunci). **Tidak ada gembok dan tidak ada
/// hitungan** (KT-G1). Tiap stempel punya sudut tetap [rotation] agar terasa
/// dicap tangan; tentukan per id, bukan acak tiap render.
///
/// [isNew] menambah cincin emas yang berdenyut pelan; berhenti bila gerak
/// dikurangi (`DsMotion.reduced`). Gambar `excludeSemantics`: pembaca layar
/// memakai [semanticLabel], bukan ikonnya.
class DsStampSeal extends StatefulWidget {
  /// Membuat [DsStampSeal].
  const DsStampSeal({
    required this.asset,
    required this.semanticLabel,
    this.earned = true,
    this.isNew = false,
    this.size = DsStampSealSize.md,
    this.rotation = -6,
    super.key,
  });

  /// Aset ikon clay di tengah.
  final String asset;

  /// Label pembaca layar, mis. "Dompet pertama, diraih 25 Okt".
  final String semanticLabel;

  /// Diraih (hijau dan emas) atau terkunci (abu-abu).
  final bool earned;

  /// Stempel yang belum dilihat: cincin emas berdenyut.
  final bool isNew;

  /// Ukuran segel.
  final DsStampSealSize size;

  /// Sudut miring tetap, derajat.
  final double rotation;

  @override
  State<DsStampSeal> createState() => _DsStampSealState();
}

class _DsStampSealState extends State<DsStampSeal> with SingleTickerProviderStateMixin {
  AnimationController? _ring;

  bool get _animates => widget.earned && widget.isNew && !DsMotion.reduced(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(DsStampSeal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (_animates) {
      _ring ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
      if (!_ring!.isAnimating) _ring!.repeat();
    } else {
      _ring?.stop();
    }
  }

  @override
  void dispose() {
    _ring?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final d = widget.size.diameter;
    final earned = widget.earned;
    final ringWidth = d >= 100 ? 3.0 : 2.0;
    final face = Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: earned
          ? BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                radius: 0.9,
                colors: [c.stampSeal, c.stampSealDeep],
                stops: const [0, 0.7],
              ),
              border: Border.all(color: c.stampGold, width: ringWidth),
              boxShadow: [
                BoxShadow(
                  color: c.stampSealDeep.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            )
          : BoxDecoration(
              shape: BoxShape.circle,
              color: ds.colors.surfaceSunken,
              border: Border.all(color: ds.colors.outlineStrong, width: ringWidth),
            ),
      child: Opacity(
        opacity: earned ? 1 : 0.4,
        child: ColorFiltered(
          colorFilter: earned
              ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
              : const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0, //
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
          child: SvgPicture.asset(widget.asset, width: widget.size.icon, height: widget.size.icon),
        ),
      ),
    );
    final ring = _ring;
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      excludeSemantics: true,
      child: Transform.rotate(
        angle: widget.rotation * math.pi / 180,
        child: SizedBox(
          width: d,
          height: d,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (ring != null && _animates)
                AnimatedBuilder(
                  animation: ring,
                  builder: (context, _) {
                    final t = ring.value;
                    final scale = 0.85 + 0.33 * (t / 0.7).clamp(0, 1);
                    final alpha = t < 0.7 ? 0.8 * (1 - t / 0.7) : 0.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: d + 10,
                        height: d + 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.stampGoldDeep.withValues(alpha: alpha), width: 2),
                        ),
                      ),
                    );
                  },
                ),
              face,
            ],
          ),
        ),
      ),
    );
  }
}
