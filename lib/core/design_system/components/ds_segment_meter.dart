import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Varian [DsSegmentMeter].
enum DsSegmentMeterVariant {
  /// Tinggi 6, segmen pil: kesehatan/mood.
  health,

  /// Tinggi 10, sudut 4: pemakaian anggaran.
  budget,
}

/// Status warna isi [DsSegmentMeter].
enum DsMeterTone {
  /// Aman: hijau.
  normal,

  /// Hampir habis: kuning.
  warning,

  /// Lewat batas: merah.
  danger,
}

/// Meter tersegmen: segmen sama lebar berjarak 4px, terisi dari kiri.
///
/// [value] 0–1; segmen terisi = `floor(value × segments)`, tetapi nilai di
/// atas 0 selalu mengisi minimal satu segmen (anggaran terpakai 5% tidak
/// boleh tampak kosong). [pace] (0–1) menambah garis penanda seberapa jauh
/// periode sudah berjalan. [thin] memakai tinggi 6 untuk baris pos. Pada varian
/// [DsSegmentMeterVariant.budget] segmen terisi terakhir sedikit lebih
/// terang sebagai penanda posisi.
///
/// [breathing] menghidupkan segmen terisi: tiap segmen mengembang-mengempis
/// (2,2 dtk, bergantian 0,15 dtk) dan kilau putih menyapu. Hanya memakai
/// skala dan keburaman (tanpa bayangan beranimasi, referensi memakainya
/// dan mahal dirender). Berhenti saat gerak dikurangi.
class DsSegmentMeter extends StatefulWidget {
  /// Membuat meter.
  const DsSegmentMeter({
    required this.value,
    required this.semanticLabel,
    this.variant = DsSegmentMeterVariant.budget,
    this.tone = DsMeterTone.normal,
    this.segments = 10,
    this.breathing = false,
    this.pace,
    this.thin = false,
    super.key,
  });

  /// Bagian terisi, 0–1 (dipotong ke rentang itu).
  final double value;

  /// Varian ukuran.
  final DsSegmentMeterVariant variant;

  /// Warna isi.
  final DsMeterTone tone;

  /// Jumlah segmen.
  final int segments;

  /// Segmen terisi bernapas dan berkilau.
  final bool breathing;

  /// Label pembaca layar, mis. "74% terpakai".
  final String semanticLabel;

  /// Rasio periode yang sudah berjalan (0–1), atau `null` tanpa penanda.
  final double? pace;

  /// Tinggi 6 untuk varian anggaran (baris pos).
  final bool thin;

  /// Jumlah segmen terisi untuk [value]; nilai positif minimal satu segmen.
  static int filledFor(double value, int segments) {
    final v = value.clamp(0, 1);
    final filled = (v * segments).floor();
    return filled == 0 && v > 0 ? 1 : filled;
  }

  @override
  State<DsSegmentMeter> createState() => _DsSegmentMeterState();
}

class _DsSegmentMeterState extends State<DsSegmentMeter> with TickerProviderStateMixin {
  static const double _period = 2.2;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  /// Isi tumbuh sekali saat pertama tampil: segmen terisi menyala berurutan.
  late final AnimationController _grow = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool _grown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_grown) {
      _grown = true;
      if (DsMotion.reduced(context)) {
        _grow.value = 1;
      } else {
        _grow.forward();
      }
    }
    _sync();
  }

  @override
  void didUpdateWidget(DsSegmentMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.breathing && !DsMotion.reduced(context);
    if (run && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!run) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _grow.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final filled = DsSegmentMeter.filledFor(widget.value, widget.segments);
    final fill = switch (widget.tone) {
      DsMeterTone.normal => c.actionPrimary,
      DsMeterTone.warning => c.warning,
      DsMeterTone.danger => c.error,
    };
    final health = widget.variant == DsSegmentMeterVariant.health;
    final radius = health ? DsRadius.fullAll : DsRadius.smAll;

    Widget segment(int i, double seconds) {
      final isFilled = i < filled;
      final target = !isFilled
          ? c.surfaceContainerHigh
          : (!health && widget.tone == DsMeterTone.normal && i == filled - 1 ? c.surfaceTint : fill);
      // Segmen terisi menyala berurutan dari kiri selama 900 ms pertama.
      final lit = isFilled ? ((_grow.value * (filled + 3) - i) / 3).clamp(0.0, 1.0) : 1.0;
      final color = isFilled ? Color.lerp(c.surfaceContainerHigh, target, lit)! : target;
      Widget box = DecoratedBox(
        decoration: BoxDecoration(borderRadius: radius, color: color),
      );
      if (isFilled && widget.breathing && _controller.isAnimating) {
        // Napas: 0→1→0 dalam satu periode, tiap segmen tertunda 0,15 dtk.
        final phase = (((seconds - 0.15 * i) % _period) + _period) % _period / _period;
        final breath = (1 - math.cos(2 * math.pi * phase)) / 2;
        // Kilau: sapuan kiri-ke-kanan, tertunda 0,25 dtk per segmen.
        final sweep = (((seconds - 0.25 * i - 0.1) % _period) + _period) % _period / _period;
        box = Opacity(
          opacity: 0.9 + 0.1 * breath,
          child: Transform.scale(
            scaleX: 1 + 0.02 * breath,
            scaleY: 1 + 0.15 * breath,
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  box,
                  FractionalTranslation(
                    translation: Offset(-1 + 3 * sweep, 0),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0x00FFFFFF), Color(0x73FFFFFF), Color(0x00FFFFFF)]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return Expanded(child: box);
    }

    return Semantics(
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: health || widget.thin ? 6 : 10,
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, _grow]),
            builder: (context, _) {
              final seconds = _controller.value * _period;
              final row = Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < widget.segments; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    segment(i, seconds),
                  ],
                ],
              );
              final pace = widget.pace;
              if (pace == null) return row;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: row),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, box) => Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: (box.maxWidth * pace.clamp(0, 1) - 1).clamp(0, box.maxWidth - 2),
                            top: -3,
                            bottom: -3,
                            width: 2,
                            child: DecoratedBox(
                              key: const ValueKey('meter-pace'),
                              decoration: BoxDecoration(
                                color: c.textPrimary,
                                borderRadius: DsRadius.fullAll,
                                border: Border.all(color: c.surfaceCard),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
