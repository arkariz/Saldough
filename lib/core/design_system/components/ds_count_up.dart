import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';

/// Angka yang berhitung naik dari 0 ke [value] saat pertama tampil, lalu
/// bergulir ke nilai baru bila [value] berubah (1,4 dtk, easeOutExpo).
///
/// Hanya menghitung; format (Rp, titik ribuan, tanda) dikerjakan [builder].
/// Saat gerak dikurangi, langsung menampilkan nilai akhir.
class DsCountUp extends StatelessWidget {
  /// Membuat hitung naik.
  const DsCountUp({
    required this.value,
    required this.builder,
    this.duration = DsMotion.countUp,
    this.curve = DsMotion.easeOutExpo,
    this.fromZero = true,
    super.key,
  });

  /// Nilai akhir.
  final int value;

  /// Membangun tampilan dari nilai yang sedang berjalan.
  final Widget Function(BuildContext context, int current) builder;

  /// Lama animasi.
  final Duration duration;

  /// Kurva animasi.
  final Curve curve;

  /// Mulai dari 0 saat pertama tampil. `false`: langsung [value].
  final bool fromZero;

  @override
  Widget build(BuildContext context) {
    if (DsMotion.reduced(context)) return builder(context, value);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: fromZero ? 0 : value.toDouble(), end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, current, _) => builder(context, current.floor()),
    );
  }
}
