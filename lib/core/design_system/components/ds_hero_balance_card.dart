import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:saldough/core/design_system/components/ds_button.dart';
import 'package:saldough/core/design_system/components/ds_flip_switcher.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Kartu saldo hero "clay" hijau hutan (acuan `reference/wallet-hero.html`,
/// ADR-043): aura bernapas di belakang kartu, latar gradasi dengan cahaya
/// samar, daun dan kilau melayang, maskot yang mengangguk dengan koin
/// berkilau, saldo besar yang menghitung naik dan mengabur saat
/// disembunyikan, kotak statistik, perkiraan di [footer], dan pita bawah
/// dengan titik berdenyut. Kartu miring mengikuti jari dan memantul balik.
///
/// Komponen hanya menampilkan teks yang sudah diformat; menyembunyikan
/// nominal diatur pemanggil lewat [hidden] dan [onToggleHidden]. Semua
/// gerak berhenti saat gerak dikurangi (`DsMotion.reduced`); hiasan tidak
/// dibacakan pembaca layar.
class DsHeroBalanceCard extends StatefulWidget {
  /// Membuat kartu saldo.
  const DsHeroBalanceCard({
    required this.label,
    required this.currencySymbol,
    required this.amount,
    required this.toggleLabel,
    this.semanticAmount,
    this.hidden = false,
    this.hiddenMask = '••••••••',
    this.onToggleHidden,
    this.caption,
    this.stats = const [],
    this.footer,
    this.mascot,
    this.coin,
    this.actions = const [],
    super.key,
  });

  /// Label kepala kapital ("TOTAL SALDO").
  final String label;

  /// Simbol mata uang ("Rp").
  final String currencySymbol;

  /// Nominal tanpa simbol ("14.850.000"); bisa angka antara saat menghitung
  /// naik.
  final String amount;

  /// Nominal akhir lengkap untuk pembaca layar ("Rp14.850.000"), supaya
  /// angka antara tidak dibacakan. Bila `null`, [amount] yang dibacakan.
  final String? semanticAmount;

  /// Saldo sedang disembunyikan.
  final bool hidden;

  /// Pengganti [amount] saat disembunyikan.
  final String hiddenMask;

  /// Dipanggil saat tombol mata diketuk; `null` menyembunyikan tombolnya.
  final VoidCallback? onToggleHidden;

  /// Label pembaca layar tombol mata ("Sembunyikan saldo").
  final String toggleLabel;

  /// Keterangan di pita bawah ("5 dompet aktif"), dengan titik berdenyut.
  final String? caption;

  /// Kotak statistik, paling banyak tiga (`DsHeroStatTile`).
  final List<Widget> stats;

  /// Baris di bawah kotak statistik (perkiraan saldo akhir periode), dari
  /// akar komposisi. `null` = tidak ada.
  final Widget? footer;

  /// Maskot yang mengintip di pojok kanan atas (≈60px). `null` = tanpa.
  final Widget? mascot;

  /// Koin kecil di kaki maskot (≈24px). Hanya tampil bersama [mascot].
  final Widget? coin;

  /// Tombol di bawah kotak statistik, paling banyak dua. Bawaan kosong;
  /// Beranda tidak memakainya.
  final List<Widget> actions;

  @override
  State<DsHeroBalanceCard> createState() => _DsHeroBalanceCardState();
}

class _DsHeroBalanceCardState extends State<DsHeroBalanceCard> with SingleTickerProviderStateMixin {
  /// Kemiringan maksimum (derajat) mengikuti jari.
  static const double _maxTilt = 9;

  final ValueNotifier<double> _seconds = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker((elapsed) => _seconds.value = elapsed.inMicroseconds / 1e6);

  double _tiltX = 0;
  double _tiltY = 0;
  bool _pressed = false;
  int _eyeBounce = 0;

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
  void didUpdateWidget(DsHeroBalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hidden != oldWidget.hidden) _eyeBounce++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  void _tilt(PointerEvent event) {
    if (DsMotion.reduced(context)) return;
    final size = context.size;
    if (size == null || size.isEmpty) return;
    final dx = event.localPosition.dx - size.width / 2;
    final dy = event.localPosition.dy - size.height / 2;
    setState(() {
      _tiltX = (-dy / size.height * _maxTilt).clamp(-_maxTilt, _maxTilt);
      _tiltY = (dx / size.width * _maxTilt).clamp(-_maxTilt, _maxTilt);
    });
  }

  void _release() => setState(() {
    _tiltX = 0;
    _tiltY = 0;
    _pressed = false;
  });

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final reduced = DsMotion.reduced(context);
    final base = c.heroSurface;
    const radius = DsRadius.xlAll;

    // Latar gradasi diagonal (acuan: #1f572e → #154322 → #082d15), diturunkan
    // dari warna dasar supaya ikut preset.
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(base, Colors.white, 0.08)!,
        Color.lerp(base, Colors.black, 0.22)!,
        Color.lerp(base, Colors.black, 0.5)!,
      ],
      stops: const [0, 0.45, 1],
    );

    final matrix = Matrix4.identity();
    if (_tiltX != 0 || _tiltY != 0 || _pressed) {
      matrix
        ..setEntry(3, 2, 0.0012)
        ..rotateX(_tiltX * math.pi / 180)
        ..rotateY(_tiltY * math.pi / 180);
      if (_pressed) matrix.scaleByDouble(0.985, 0.985, 1, 1);
    }

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: c.primaryFixed.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(color: base.withValues(alpha: 0.35), offset: const Offset(0, 16), blurRadius: 32, spreadRadius: -6),
          BoxShadow(color: base.withValues(alpha: 0.22), offset: const Offset(0, 6), blurRadius: 16, spreadRadius: -2),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: gradient))),
            // Cahaya samar statis (di-cache sebagai satu lapisan).
            Positioned.fill(
              child: RepaintBoundary(
                child: ExcludeSemantics(
                  child: IgnorePointer(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(right: -32, bottom: -40, child: _Glow(color: base, alpha: 0.7, size: 176, sigma: 24)),
                        Positioned(left: -40, top: -40, child: _Glow(color: c.primaryFixed, alpha: 0.15, size: 144, sigma: 20)),
                        Positioned(left: 110, top: 0, child: _Glow(color: c.surfaceTint, alpha: 0.25, size: 120, sigma: 24)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Daun dan kilau melayang, maskot, dan koin.
            Positioned.fill(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: ListenableBuilder(
                      listenable: _seconds,
                      builder: (context, _) => _Decor(
                        seconds: reduced ? 0 : _seconds.value,
                        animate: !reduced,
                        leafColor: c.primaryFixed,
                        sparkleColor: c.heroAccentWarm,
                        mascot: widget.mascot,
                        coin: widget.coin,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Kilap clay: tepi atas terang, tepi bawah gelap (pengganti
            // bayangan dalam `inset` CSS).
            Positioned.fill(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.28),
                        ],
                        stops: const [0, 0.1, 0.85, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(20), child: _content(context)),
          ],
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Aura bernapas di belakang kartu.
        Positioned(
          left: -4,
          right: -4,
          top: -4,
          bottom: -4,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ListenableBuilder(
                  listenable: _seconds,
                  builder: (context, _) {
                    final s = reduced ? 0.5 : _loop(_seconds.value, 4.5);
                    return Opacity(
                      opacity: 0.45 + 0.4 * s,
                      child: Transform.scale(
                        scale: 1 + 0.12 * s,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: radius,
                              gradient: LinearGradient(
                                colors: [
                                  c.primaryFixed.withValues(alpha: 0.2),
                                  c.surfaceTint.withValues(alpha: 0.3),
                                  c.primary.withValues(alpha: 0.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Listener(
          onPointerDown: (e) {
            if (reduced) return;
            setState(() => _pressed = true);
            _tilt(e);
          },
          onPointerMove: _tilt,
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(),
          child: AnimatedContainer(
            duration: reduced ? Duration.zero : const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            transformAlignment: Alignment.center,
            transform: matrix,
            child: card,
          ),
        ),
      ],
    );
  }

  Widget _content(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final amountStyle = ds.typography.displayLg.copyWith(
      color: c.onHero,
      fontFeatures: const [FontFeature.tabularFigures(), FontFeature.liningFigures()],
    );
    final fullLabel = widget.semanticAmount ?? '${widget.currencySymbol}${widget.amount}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kepala: token daun + label, tombol mata di kiri maskot.
        Padding(
          padding: const EdgeInsets.only(right: 52),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: c.primaryFixed,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 2), blurRadius: 4)],
                ),
                child: Icon(Icons.eco, size: 15, color: c.onPrimaryFixed),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  style: ds.typography.labelMd.copyWith(color: c.primaryFixed, letterSpacing: 1),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.onToggleHidden != null)
                DsIconButton.onHero(
                  icon: widget.hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  label: widget.toggleLabel,
                  onPressed: widget.onToggleHidden,
                  bounceTrigger: _eyeBounce,
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Saldo besar: menghitung naik, mengabur saat disembunyikan.
        Semantics(
          label: widget.hidden ? widget.hiddenMask : fullLabel,
          excludeSemantics: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.currencySymbol,
                style: ds.typography.headlineSm.copyWith(color: c.primaryFixed, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: DsBlurSwitcher(
                    child: Text(
                      widget.hidden ? widget.hiddenMask : widget.amount,
                      key: ValueKey(widget.hidden),
                      style: amountStyle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.stats.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(children: _spaced(widget.stats, 8)),
        ],
        if (widget.footer != null) ...[const SizedBox(height: 10), widget.footer!],
        if (widget.actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(children: _spaced(widget.actions, 8)),
        ],
        if (widget.caption != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                DsPingDot(color: c.primaryFixed, reduced: DsMotion.reduced(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.caption!,
                    style: ds.typography.bodySm.copyWith(color: c.onHero, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Gerak bolak-balik halus 0→1→0 dalam satu [period] detik.
  static double _loop(double seconds, double period, {double delay = 0}) {
    if (seconds < delay) return 0;
    final u = (seconds - delay) / period;
    return (1 - math.cos(2 * math.pi * u)) / 2;
  }

  static List<Widget> _spaced(List<Widget> items, double gap) => [
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) SizedBox(width: gap),
      Expanded(child: items[i]),
    ],
  ];
}

/// Lapisan hiasan bergerak: dua daun, dua kilau, maskot, dan koin.
class _Decor extends StatelessWidget {
  const _Decor({
    required this.seconds,
    required this.animate,
    required this.leafColor,
    required this.sparkleColor,
    required this.mascot,
    required this.coin,
  });

  final double seconds;
  final bool animate;
  final Color leafColor;
  final Color sparkleColor;
  final Widget? mascot;
  final Widget? coin;

  @override
  Widget build(BuildContext context) {
    double loop(double period, {double delay = 0}) =>
        animate ? _DsHeroBalanceCardState._loop(seconds, period, delay: delay) : 0;
    final leaf1 = loop(6);
    final leaf2 = loop(5.2, delay: 1);
    final spark1 = loop(3.2);
    final spark2 = loop(3.8, delay: 1.5);
    final nodU = animate ? (seconds / 5.5) % 1 : 0.0;
    final nodY = dsKeyframes(nodU, [(0, 0), (0.3, -3), (0.6, 1), (1, 0)]);
    final nodA = dsKeyframes(nodU, [(0, 0), (0.3, 2), (0.6, -1), (1, 0)]);
    final shine = loop(3.6);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 112,
          top: 12,
          child: Transform.translate(
            offset: Offset(-6 * leaf1, -8 * leaf1),
            child: Transform.rotate(angle: 14 * leaf1 * math.pi / 180, child: _Leaf(color: leafColor.withValues(alpha: 0.4), size: 16)),
          ),
        ),
        Positioned(
          left: 24,
          bottom: 56,
          child: Transform.translate(
            offset: Offset(7 * leaf2, -6 * leaf2),
            child: Transform.rotate(angle: -18 * leaf2 * math.pi / 180, child: _Leaf(color: leafColor.withValues(alpha: 0.35), size: 14)),
          ),
        ),
        Positioned(
          right: 112,
          top: 40,
          child: Opacity(
            opacity: 0.35 + 0.5 * spark1,
            child: Transform.scale(scale: 1 + 0.08 * spark1, child: Icon(Icons.auto_awesome, size: 12, color: sparkleColor)),
          ),
        ),
        Positioned(
          right: 128,
          bottom: 80,
          child: Opacity(
            opacity: 0.35 + 0.5 * spark2,
            child: Transform.scale(scale: 1 + 0.08 * spark2, child: Icon(Icons.auto_awesome, size: 10, color: sparkleColor)),
          ),
        ),
        if (mascot != null)
          Positioned(
            right: 6,
            top: 6,
            child: Transform.translate(
              offset: Offset(0, nodY),
              child: Transform.rotate(
                angle: nodA * math.pi / 180,
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(child: mascot!),
                      if (coin != null)
                        Positioned(
                          left: -6,
                          bottom: -2,
                          child: Transform.rotate(
                            angle: (-12 + 4 * shine) * math.pi / 180,
                            child: Transform.scale(scale: 1 + 0.06 * shine, child: coin),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Leaf extends StatelessWidget {
  const _Leaf({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Icon(Icons.eco, size: size, color: color);
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.alpha, required this.size, required this.sigma});

  final Color color;
  final double alpha;
  final double size;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color.withValues(alpha: alpha), shape: BoxShape.circle),
      ),
    );
  }
}

/// Titik berdenyut (ping): lingkaran membesar dan memudar di belakang titik
/// pejal, satu putaran per detik. Diam saat [reduced].
class DsPingDot extends StatefulWidget {
  /// Membuat titik berdenyut.
  const DsPingDot({required this.color, this.size = 8, this.reduced = false, super.key});

  /// Warna titik.
  final Color color;

  /// Diameter titik pejal.
  final double size;

  /// Gerak dikurangi: hanya titik pejal.
  final bool reduced;

  @override
  State<DsPingDot> createState() => _DsPingDotState();
}

class _DsPingDotState extends State<DsPingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    if (!widget.reduced) _controller.repeat();
  }

  @override
  void didUpdateWidget(DsPingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduced) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.size * 2,
        height: widget.size * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!widget.reduced)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = Curves.easeOut.transform(_controller.value);
                  return Opacity(
                    opacity: 0.75 * (1 - t),
                    child: Transform.scale(scale: 1 + t, child: dot),
                  );
                },
              ),
            dot,
          ],
        ),
      ),
    );
  }
}

/// Kotak statistik di kartu saldo hero (Masuk, Keluar, Kesehatan): latar
/// hitam 25%, garis putih 15%, sudut 12, dengan label kecil ber-ikon atau
/// titik berdenyut, dan nilai tebal.
class DsHeroStatTile extends StatelessWidget {
  /// Membuat kotak statistik.
  const DsHeroStatTile({
    required this.label,
    required this.value,
    this.icon,
    this.income = true,
    this.pulse = false,
    this.suffix,
    super.key,
  });

  /// Ikon label (mis. `Icons.arrow_circle_up`); diabaikan bila [pulse].
  final IconData? icon;

  /// Label kecil ("Masuk").
  final String label;

  /// Nilai yang sudah diformat ("+Rp8.500.000").
  final String value;

  /// Nada pemasukan (hijau muda) atau pengeluaran (kuning).
  final bool income;

  /// Titik berdenyut menggantikan ikon (penanda keadaan hidup).
  final bool pulse;

  /// Teks kecil di samping nilai ("Sehat").
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final tone = income ? c.primaryFixed : c.heroAccentWarm;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: DsRadius.mdAll,
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: const [BoxShadow(color: Color(0x26000000), offset: Offset(0, 2), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (pulse)
                DsPingDot(color: tone, size: 6, reduced: DsMotion.reduced(context))
              else if (icon != null)
                Icon(icon, size: 13, color: tone),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: ds.typography.labelSm.copyWith(fontSize: 10, color: tone, letterSpacing: 0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  style: ds.typography.amountSm.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontVariations: const [FontVariation.weight(700)],
                    color: pulse ? tone : c.onHero,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Text(suffix!, style: ds.typography.labelSm.copyWith(fontSize: 10, color: tone.withValues(alpha: 0.8))),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
