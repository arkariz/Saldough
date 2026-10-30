import 'package:flutter/widgets.dart';

/// Gerak design system baru (`spec.md`: transisi 150ms renyah; durasi dan
/// kurva animasi dari referensi `reference/home-motion.html`, ADR-043).
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

  /// Hitung naik angka saat layar dibuka (1,4 dtk).
  static const Duration countUp = Duration(milliseconds: 1400);

  /// easeOutExpo, kurva hitung naik.
  static const Curve easeOutExpo = Cubic(0.16, 1, 0.3, 1);

  /// Balik keluar nominal saat disembunyikan.
  static const Duration flipOut = Duration(milliseconds: 200);

  /// Balik masuk nominal.
  static const Duration flipIn = Duration(milliseconds: 250);

  /// Perpindahan slide dan lebar titik indikator carousel.
  static const Duration carousel = Duration(milliseconds: 300);

  /// Goyang badge level.
  static const Duration jiggle = Duration(milliseconds: 750);

  /// Ledakan perayaan.
  static const Duration burst = Duration(milliseconds: 1300);

  /// Tulisan hadiah yang melayang naik.
  static const Duration floatLabel = Duration(milliseconds: 1200);

  /// Lama tooltip ketuk tampil.
  static const Duration tip = Duration(milliseconds: 2400);

  /// Gulir (px) mulai app bar menyusut.
  static const double collapseStart = 110;

  /// Gulir (px) app bar sepenuhnya menyusut.
  static const double collapseEnd = 240;

  /// Pengguna meminta gerak dikurangi (`disableAnimations`). Semua
  /// animasi berulang, partikel, dan perayaan berhenti; perubahan keadaan
  /// tampil langsung.
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Interpolasi linear antar titik kunci `(posisi 0–1, nilai)` yang urut,
/// seperti `@keyframes` CSS. Di luar rentang dipotong ke ujung.
double dsKeyframes(double t, List<(double, double)> keys) {
  if (t <= keys.first.$1) return keys.first.$2;
  for (var i = 1; i < keys.length; i++) {
    final (end, endValue) = keys[i];
    if (t <= end) {
      final (start, startValue) = keys[i - 1];
      return startValue + (endValue - startValue) * ((t - start) / (end - start));
    }
  }
  return keys.last.$2;
}
