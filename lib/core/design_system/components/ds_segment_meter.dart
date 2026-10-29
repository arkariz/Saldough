import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
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
class DsSegmentMeter extends StatelessWidget {
  /// Membuat meter.
  const DsSegmentMeter({
    required this.value,
    required this.semanticLabel,
    this.variant = DsSegmentMeterVariant.budget,
    this.tone = DsMeterTone.normal,
    this.segments = 10,
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

  /// Label pembaca layar, mis. "74% terpakai".
  final String semanticLabel;

  /// Jumlah segmen terisi untuk [value].
  static int filledFor(double value, int segments) => (value.clamp(0, 1) * segments).floor();

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final filled = filledFor(value, segments);
    final fill = switch (tone) {
      DsMeterTone.normal => c.actionPrimary,
      DsMeterTone.warning => c.warning,
      DsMeterTone.danger => c.error,
    };
    final health = variant == DsSegmentMeterVariant.health;
    final radius = health ? DsRadius.fullAll : DsRadius.smAll;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: health ? 6 : 10,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < segments; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      color: i >= filled
                          ? c.surfaceContainerHigh
                          : (!health && tone == DsMeterTone.normal && i == filled - 1 ? c.surfaceTint : fill),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
