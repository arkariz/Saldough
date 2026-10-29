import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/color/ds_color_scheme.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Satu tingkat permukaan: warna isi, bingkai 1px, dan bayangan.
@immutable
class DsSurfaceTier {
  /// Membuat tingkat permukaan.
  const DsSurfaceTier({required this.color, required this.border, required this.shadows});

  /// Interpolasi dua tingkat.
  factory DsSurfaceTier.lerp(DsSurfaceTier a, DsSurfaceTier b, double t) => DsSurfaceTier(
    color: Color.lerp(a.color, b.color, t)!,
    border: Color.lerp(a.border, b.border, t)!,
    shadows: BoxShadow.lerpList(a.shadows, b.shadows, t) ?? const [],
  );

  /// Warna isi permukaan.
  final Color color;

  /// Warna bingkai 1px; [Colors.transparent] bila tanpa bingkai.
  final Color border;

  /// Bayangan sekitar yang nyaris tak terlihat.
  final List<BoxShadow> shadows;

  /// [BoxDecoration] siap pakai dengan sudut [radius].
  BoxDecoration decoration({BorderRadius radius = DsRadius.lgAll}) => BoxDecoration(
    color: color,
    borderRadius: radius,
    border: border.a == 0 ? null : Border.all(color: border),
    boxShadow: shadows,
  );
}

/// Elevasi design system baru (`spec.md` bagian Elevation & Depth,
/// ADR-043): kedalaman lewat garis rambut dan lapisan nada, tanpa bayangan
/// jatuh yang berat. Keadaan ditekan/aktif tidak menaikkan tingkat; ia
/// mengganti bingkai ke `outlineFocus` atau isi ke `surfaceHover`.
@immutable
class DsElevation extends ThemeExtension<DsElevation> {
  /// Membuat elevasi.
  const DsElevation({required this.canvas, required this.card, required this.overlay});

  /// Elevasi dari [colors]. Bayangan kartu dari referensi komponen
  /// (`0 2px 8px` hitam 3%); spek sendiri menyebut kartu tanpa bayangan,
  /// jadi nilainya sengaja nyaris tak terlihat. Mode gelap tanpa bayangan
  /// kartu.
  factory DsElevation.from(DsColorScheme colors, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return DsElevation(
      canvas: DsSurfaceTier(color: colors.surfaceCanvas, border: Colors.transparent, shadows: const []),
      card: DsSurfaceTier(
        color: colors.surfaceCard,
        border: colors.outlineSubtle,
        shadows: dark
            ? const []
            : const [BoxShadow(color: Color(0x08000000), offset: Offset(0, 2), blurRadius: 8)],
      ),
      overlay: DsSurfaceTier(
        color: colors.surfaceOverlay,
        border: colors.outlineOverlay,
        shadows: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: dark ? 0.4 : 0.04),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
    );
  }

  /// Tingkat 0: kanvas dasar.
  final DsSurfaceTier canvas;

  /// Tingkat 1: kartu, daftar, kolom input.
  final DsSurfaceTier card;

  /// Tingkat 2: popover, dialog, sheet.
  final DsSurfaceTier overlay;

  @override
  DsElevation copyWith({DsSurfaceTier? canvas, DsSurfaceTier? card, DsSurfaceTier? overlay}) {
    return DsElevation(
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  DsElevation lerp(ThemeExtension<DsElevation>? other, double t) {
    if (other is! DsElevation) return this;
    return DsElevation(
      canvas: DsSurfaceTier.lerp(canvas, other.canvas, t),
      card: DsSurfaceTier.lerp(card, other.card, t),
      overlay: DsSurfaceTier.lerp(overlay, other.overlay, t),
    );
  }
}
