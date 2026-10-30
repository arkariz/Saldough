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
/// [value] 0–1; segmen terisi = `floor(value × segments)`. Pada varian
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

  /// Jumlah segmen terisi untuk [value].
  static int filledFor(double value, int segments) => (value.clamp(0, 1) * segments).floor();

  @override
  State<DsSegmentMeter> createState() => _DsSegmentMeterState();
}

class _DsSegmentMeterState extends State<DsSegmentMeter> with SingleTickerProviderStateMixin {
  static const double _period = 2.2;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
      final color = !isFilled
          ? c.surfaceContainerHigh
          : (!health && widget.tone == DsMeterTone.normal && i == filled - 1 ? c.surfaceTint : fill);
      Widget box = DecoratedBox(decoration: BoxDecoration(borderRadius: radius, color: color));
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
          height: health ? 6 : 10,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final seconds = _controller.value * _period;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < widget.segments; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    segment(i, seconds),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
