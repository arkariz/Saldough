import 'package:flutter/animation.dart';

/// Gerak design system baru (`spec.md`: transisi 150ms renyah, ADR-043).
abstract final class DsMotion {
  DsMotion._();

  /// Transisi standar (150ms).
  static const Duration standard = Duration(milliseconds: 150);

  /// Kurva transisi standar (ease-out).
  static const Curve curve = Curves.easeOut;

  /// Skala saat tombol atau kartu ditekan (referensi `active:scale-[0.98]`).
  static const double pressScale = 0.98;

  /// Skala saat tile kecil ditekan (referensi `active:scale-95`).
  static const double pressScaleTile = 0.95;
}
