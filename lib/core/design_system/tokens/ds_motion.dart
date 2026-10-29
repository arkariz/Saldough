import 'package:flutter/animation.dart';

/// Gerak design system baru (spek bagian Buttons, ADR-043).
abstract final class DsMotion {
  DsMotion._();

  /// Transisi tekan tombol (100ms).
  static const Duration press = Duration(milliseconds: 100);

  /// Kurva transisi tekan. Spek hanya menyebut "cubic-bezier"; dipakai
  /// kurva standar Material.
  static const Curve pressCurve = Cubic(0.2, 0, 0, 1);

  /// Geseran ke bawah saat tombol ditekan (px).
  static const double pressOffset = 1;
}
