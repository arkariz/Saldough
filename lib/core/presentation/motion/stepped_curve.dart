import 'package:flutter/animation.dart';

/// Kurva yang mengkuantisasi progres ke [steps] anak tangga, supaya gerak
/// terasa seperti sprite 8-bit (ADR-021 §3.7). [curve] diterapkan dulu,
/// lalu hasilnya dibulatkan ke bawah ke anak tangga terdekat.
class SteppedCurve extends Curve {
  /// Membuat [SteppedCurve] dengan [steps] anak tangga di atas [curve].
  const SteppedCurve(this.steps, {this.curve = Curves.linear}) : assert(steps > 0, 'steps harus positif');

  /// Jumlah anak tangga.
  final int steps;

  /// Kurva dasar sebelum dikuantisasi.
  final Curve curve;

  @override
  double transformInternal(double t) {
    if (t >= 1) return 1;
    return (curve.transform(t) * steps).floorToDouble() / steps;
  }
}

/// Membulatkan [value] ke grid logis [grid] piksel, supaya posisi hasil
/// animasi tetap "di atas piksel".
double snapToPixelGrid(double value, {double grid = 2}) => (value / grid).roundToDouble() * grid;
